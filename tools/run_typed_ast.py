"""Archive a typed AST from the actual pinned XLA compile configuration."""
import argparse
import gzip
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT=Path(__file__).resolve().parents[1]
SOURCE='xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
COMMIT='e58e523b11f1fde802a493a776d158007486e1bf'
PASS_SHA='1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f'


def digest(path):
    result=hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda:stream.read(1024*1024),b''):result.update(chunk)
    return result.hexdigest()


def ast_arguments(arguments,compiler):
    """Retain preprocessing/type flags; omit object/dependency output generation."""
    result=[compiler]
    removed=[]
    index=1
    while index<len(arguments):
        item=arguments[index]
        if item in ('-o','-MF','-MT','-MQ'):
            removed.extend(arguments[index:index+2]);index+=2
        elif item in ('-c','-MMD','-MD','-MP') or item.startswith('-frandom-seed='):
            removed.append(item);index+=1
        else:
            result.append(item);index+=1
    result+=['-fno-color-diagnostics','-fsyntax-only','-Xclang','-ast-dump=json',
             '-Xclang','-ast-dump-filter=xla::']
    assert SOURCE in result
    return result,removed


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--action-json',required=True)
    parser.add_argument('--archive',required=True)
    args=parser.parse_args()
    if not re.fullmatch(r'typed-ast-v[0-9]+',args.archive):raise ValueError('explicit typed-ast-vN required')
    folder=ROOT/'reports'/args.archive
    if folder.exists():raise ValueError('refusing to overwrite an archive')
    repo=ROOT/'external/xla';execution=(repo/'bazel-xla').resolve()
    assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=repo,text=True).strip()==COMMIT
    assert digest(repo/SOURCE)==PASS_SHA
    action=json.loads(Path(args.action_json).read_text())
    environment=dict(os.environ)
    environment.update({e['key']:e['value'] for e in action['environmentVariables']})
    compiler=environment['GCC_PATH']
    command,removed=ast_arguments(action['arguments'],compiler)
    folder.mkdir()
    (folder/'action.json').write_text(json.dumps(action,indent=2)+'\n')
    version=subprocess.check_output([compiler,'--version'],cwd=execution,text=True)
    started=time.monotonic()
    temporary=folder/'ast.jsons.tmp'
    with temporary.open('wb') as output,(folder/'compiler.log').open('wb') as log:
        run=subprocess.run(command,cwd=execution,env=environment,stdout=output,stderr=log)
    elapsed=time.monotonic()-started
    raw_size=temporary.stat().st_size
    raw_sha=digest(temporary)
    with temporary.open('rb') as source,gzip.open(folder/'ast.jsons.gz','wb',compresslevel=6) as target:
        shutil.copyfileobj(source,target)
    temporary.unlink()
    result=dict(schema=1,status='typed_ast_compilation_completed' if run.returncode==0 else 'typed_ast_failed',
                source_commit=COMMIT,source_sha256=PASS_SHA,exit_code=run.returncode,
                elapsed_seconds=elapsed,compiler_version=version,compiler_sha256=digest(execution/compiler),
                command=command,removed_output_flags=removed,execution_root=str(execution),
                filter='xla::',raw_ast_bytes=raw_size,raw_ast_sha256=raw_sha,
                accepted_source_rewrites=0,denominator_frozen=False,
                scope='typed declarations/call expressions; not runtime effects, proof extraction or virtual target closure',
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in sorted(folder.iterdir()) if p.is_file()])
    (folder/'result.json').write_text(json.dumps(result,indent=2)+'\n')
    print(json.dumps({k:result[k] for k in ('status','exit_code','elapsed_seconds','raw_ast_bytes')},indent=2))
    if run.returncode:raise SystemExit(run.returncode)


if __name__=='__main__':main()
