"""Extract source declarations from concatenated Clang JSON documents, bounded by one document."""
import argparse
import gzip
import json
from pathlib import Path
import time
from run_typed_ast import ROOT,SOURCE,digest

DECLARATIONS={'FunctionDecl','CXXMethodDecl','CXXConstructorDecl','CXXDestructorDecl',
              'CXXConversionDecl','FunctionTemplateDecl','CXXRecordDecl','RecordDecl'}


def documents(stream):
    decoder=json.JSONDecoder()
    buffer=''
    eof=False
    while True:
        buffer=buffer.lstrip()
        if not buffer and eof:return
        try:
            value,end=decoder.raw_decode(buffer)
        except json.JSONDecodeError:
            if eof:raise
            # Grow geometrically for a large declaration instead of reparsing
            # every accumulated prefix after each fixed-size chunk.
            chunk=stream.read(max(1024*1024,len(buffer)))
            buffer+=chunk
            eof=not chunk
            if not buffer.strip() and eof:return
            continue
        yield value
        buffer=buffer[end:]


def primary_file(node):
    location=node.get('loc',{})
    if 'file' in location:return location['file']
    for key in ('expansionLoc','spellingLoc'):
        if 'file' in location.get(key,{}):return location[key]['file']
    return node.get('range',{}).get('begin',{}).get('file')


def walk(node):
    pending=[node]
    while pending:
        item=pending.pop()
        yield item
        pending.extend(reversed(item.get('inner',[])))


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--archive',default='typed-ast-v1')
    args=parser.parse_args()
    folder=ROOT/'reports'/args.archive
    result=json.loads((folder/'result.json').read_text())
    assert result['exit_code']==0 and result['source_sha256']==digest(ROOT/'sources/xla'/SOURCE)
    archive=folder/'ast.jsons.gz'
    assert digest(archive)==next(f['sha256'] for f in result['files'] if f['path'].endswith('/ast.jsons.gz'))
    output=ROOT/'reports'/('typed-main-'+args.archive+'.json.gz')
    declarations=ROOT/'reports'/('typed-declarations-'+args.archive+'.json.gz')
    metadata=ROOT/'reports'/('typed-extraction-'+args.archive+'.json')
    if any(p.exists() for p in (output,declarations,metadata)):
        raise ValueError('refusing to overwrite extracted evidence')
    roots=[]
    index={}
    count=0
    started=time.monotonic()
    with gzip.open(archive,'rt',encoding='utf-8') as stream:
        for node in documents(stream):
            count+=1
            filename=primary_file(node)
            is_main=filename==SOURCE or bool(filename and filename.endswith('/'+SOURCE))
            if is_main:roots.append(node)
            for declaration in walk(node):
                if declaration.get('kind') not in DECLARATIONS or 'id' not in declaration:continue
                row={key:declaration[key] for key in ('id','kind','name','mangledName','type','loc',
                        'range','previousDecl','parentDeclContextId','virtual','isImplicit') if key in declaration}
                row['root_file_context']=filename
                row['has_body']=any(n.get('kind')=='CompoundStmt' for n in declaration.get('inner',[]))
                index[row['id']]=row
    with gzip.open(output,'wt',encoding='utf-8') as stream:json.dump(roots,stream)
    with gzip.open(declarations,'wt',encoding='utf-8') as stream:json.dump(index,stream)
    report=dict(schema=1,source_ast=str(archive.relative_to(ROOT)),source_ast_sha256=digest(archive),
                source_sha256=result['source_sha256'],filter=result['filter'],documents=count,
                main_file_roots=len(roots),declaration_identities=len(index),
                elapsed_seconds=time.monotonic()-started,
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in (output,declarations)],
                accepted_source_rewrites=0,independent_semantic_review=False)
    metadata.write_text(json.dumps(report,indent=2)+'\n')
    print(json.dumps(report,indent=2))


if __name__=='__main__':main()
