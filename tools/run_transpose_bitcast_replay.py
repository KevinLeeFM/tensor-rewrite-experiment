"""Execute and archive a fresh transpose/bitcast replay against the pinned real XLA pass."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
TARGET = '//xla/hlo/transforms/simplifiers:transpose_bitcast_replay_test'
PASS_SHA = '1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f'
COMMIT = 'e58e523b11f1fde802a493a776d158007486e1bf'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', required=True, help='new reports/ directory basename')
    args = parser.parse_args()
    if not re.fullmatch(r'transpose-bitcast-replay-v[0-9]+', args.archive):
        raise ValueError('archive must be an explicit transpose-bitcast-replay-vN basename')
    out = ROOT / 'reports' / args.archive
    if out.exists():
        raise ValueError('refusing to overwrite an existing archive')
    repo = ROOT / 'external/xla'
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip() == COMMIT
    pass_source = repo / 'xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert digest(pass_source) == PASS_SHA
    fixture = ROOT / 'tests/xla/transpose_bitcast_replay_test.cc'
    assert digest(fixture) == digest(repo / 'xla/hlo/transforms/simplifiers' / fixture.name)
    out.mkdir()
    shutil.copyfile(fixture, out / 'fixture.cc')
    shutil.copyfile(repo / 'xla/hlo/transforms/simplifiers/BUILD', out / 'BUILD')
    command = [str(ROOT / '.build-tools/bazel'), '--output_user_root=' + str(ROOT / '.build-cache/bazel'),
               'test', TARGET, '--compilation_mode=opt', '--jobs=12',
               '--repo_env=HERMETIC_PYTHON_VERSION=3.12',
               '--repository_cache=' + str(ROOT / '.build-cache/repos'),
               '--test_output=all', '--nocache_test_results',
               '--build_event_json_file=' + str(out / 'events.json'), '--noshow_progress']
    started = time.monotonic()
    with (out / 'build.log').open('w') as log:
        run = subprocess.run(command, cwd=repo, stdout=log, stderr=subprocess.STDOUT)
    elapsed = time.monotonic() - started
    testpath = 'xla/hlo/transforms/simplifiers/transpose_bitcast_replay_test'
    for name in ('test.log', 'test.xml'):
        path = repo / 'bazel-testlogs' / testpath / name
        if path.exists():
            shutil.copyfile(path, out / name)
    log = (out / 'test.log').read_text() if (out / 'test.log').exists() else ''
    rows=re.findall(r'^TRANSPOSE_BITCAST_RESULT case=(\w+) mode=(control|handler|pass) sensitive=([01]) compatible=([01]) changed=([01]) checked=(\d+) selected=(\d+) rewritten_verified=1$',log,re.M)
    values={'default_affine':(True,True,6,3),'column_affine':(True,True,6,3),
            'wrong_layout':(True,False,6,3),'insensitive':(False,True,6,3),'rank3_cycle':(True,True,24,100)}
    expected=[(n,m,str(int(sensitive)),str(int(compatible)),str(int(m!='control' and sensitive and compatible)),str(count),str(selected))
              for n,(sensitive,compatible,count,selected) in values.items() for m in ('control','handler','pass')]
    tiled=re.findall(r'^TILED_ARRAY_SIZE_RESULT input_bytes=(\d+) output_bytes=(\d+) compatible=([01]) changed=([01]) original_verified=([01]) rewritten_verified=([01]) operator_evaluation=([01])$',log,re.M)
    binary=repo/'bazel-bin'/testpath
    passed=run.returncode==0 and rows==expected and tiled==[('32','64','1','1','1','0','0')]
    result=dict(schema=1,status='dense_transpose_preserved_tiled_arraysize_boundary_observed' if passed else 'replay_failed',
                source_commit=COMMIT,pass_source_sha256=PASS_SHA,command=command,
                xla_full_pass_run=any(m=='pass' for _,m,_,_,_,_,_ in rows),xla_handler_run=bool(rows),
                test_passed=passed,exit_code=run.returncode,elapsed_seconds=elapsed,
                binary_sha256=digest(binary) if binary.exists() else None,
                cases=[dict(name=n,mode=m,sensitive=s=='1',compatible=c=='1',changed=h=='1',checked=int(k),selected=int(v),rewritten_verified=True)
                       for n,m,s,c,h,k,v in rows],
                tiled_boundary=dict(input_bytes=32,output_bytes=64,compatible=True,changed=True,original_verified=True,rewritten_verified=False,
                    operator_evaluation=False,scope='ArraySize verifier policy; backend adoption and tiled value semantics pending') if tiled else None,
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in sorted(out.iterdir()) if p.is_file()])
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('status', 'exit_code', 'test_passed', 'elapsed_seconds')}, indent=2))
    print((out / 'build.log').read_text()[-12000:])
    if not passed:
        raise SystemExit(run.returncode or 1)


if __name__ == '__main__':
    main()
