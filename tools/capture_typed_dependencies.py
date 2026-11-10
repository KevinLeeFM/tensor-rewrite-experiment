"""Record the preprocessing dependency identities of an archived compile configuration."""
import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
from run_typed_ast import ROOT,SOURCE,ast_arguments,digest


def dependency_paths(text):
    text=text.replace('\\\n','')
    if ': ' not in text:raise ValueError('missing make dependency target')
    target,files=text.split(': ',1)
    if not target.strip():raise ValueError('empty make target')
    result=shlex.split(files)
    if not result or len(result)!=len(set(result)):raise ValueError('empty or duplicate dependency paths')
    return result


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--archive',default='typed-ast-v1')
    args=parser.parse_args()
    source=ROOT/'reports'/args.archive
    result=json.loads((source/'result.json').read_text())
    assert result['exit_code']==0
    action=json.loads((source/'action.json').read_text())
    folder=ROOT/'reports'/('dependencies-'+args.archive)
    if folder.exists():raise ValueError('refusing to overwrite dependency evidence')
    folder.mkdir()
    environment=dict(os.environ)
    environment.update({e['key']:e['value'] for e in action['environmentVariables']})
    execution=Path(result['execution_root'])
    command,_=ast_arguments(action['arguments'],environment['GCC_PATH'])
    command=command[:-6]+['-M','-MF',str(folder/'dependencies.d')]
    with (folder/'compiler.log').open('wb') as log:
        run=subprocess.run(command,cwd=execution,env=environment,stdout=log,stderr=subprocess.STDOUT)
    if run.returncode:raise RuntimeError('dependency preprocessing failed')
    paths=dependency_paths((folder/'dependencies.d').read_text())
    assert SOURCE in paths
    files=[]
    for name in paths:
        path=execution/name
        files.append(dict(path=name,sha256=digest(path),bytes=path.stat().st_size))
    assert digest(execution/SOURCE)==result['source_sha256']
    report=dict(schema=1,status='dependency_identities_captured',source_ast=str((source/'result.json').relative_to(ROOT)),
                source_result_sha256=digest(source/'result.json'),compiler_sha256=result['compiler_sha256'],
                command=command,exit_code=run.returncode,dependencies=files,
                capture_timing='after AST compilation; this is not a hermetic build closure',
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in sorted(folder.iterdir()) if p.is_file()])
    (folder/'result.json').write_text(json.dumps(report,indent=2)+'\n')
    print('Captured',len(files),'preprocessing dependencies;',sum(f['bytes'] for f in files),'bytes')


if __name__=='__main__':main()
