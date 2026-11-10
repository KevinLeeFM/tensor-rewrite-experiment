"""Execute and archive a fresh control-order replay against the pinned real XLA pass."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
TARGET = '//xla/hlo/transforms/simplifiers:control_order_replay_test'
PASS_SHA = '1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f'
COMMIT = 'e58e523b11f1fde802a493a776d158007486e1bf'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', required=True, help='new reports/ directory basename')
    args = parser.parse_args()
    if not re.fullmatch(r'control-order-replay-v[0-9]+', args.archive):
        raise ValueError('archive must be an explicit control-order-replay-vN basename')
    out = ROOT / 'reports' / args.archive
    if out.exists():
        raise ValueError('refusing to overwrite an existing archive')
    repo = ROOT / 'external/xla'
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip() == COMMIT
    pass_source = repo / 'xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert digest(pass_source) == PASS_SHA
    fixture = ROOT / 'tests/xla/control_order_replay_test.cc'
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
    testpath = 'xla/hlo/transforms/simplifiers/control_order_replay_test'
    for name in ('test.log', 'test.xml'):
        path = repo / 'bazel-testlogs' / testpath / name
        if path.exists():
            shutil.copyfile(path, out / name)
    log = (out / 'test.log').read_text() if (out / 'test.log').exists() else ''
    rows=re.findall(r'^CONTROL_ORDER_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) reachable_before=([01]) reachable_after=([01]) reverse_before=([01]) reverse_after=([01]) forward_trace=(A,B) reverse_trace=(A,B|B,A|invalid) actors_retained=1 verified=1$',log,re.M)
    expected=[]
    for name,identity,predecessor,successor in [('annihilator_successor',False,False,True),('annihilator_predecessor',False,True,True),('identity_successor',True,False,True),('annihilator_unordered',False,False,False)]:
        for mode in ('control','handler','pass'):
            changed=mode!='control' and not predecessor
            after_path=successor and not(changed and not identity)
            expected.append((name,mode,str(int(changed)),str(int(successor)),str(int(after_path)),str(int(not successor)),str(int(not after_path)),'A,B','invalid' if after_path else 'B,A'))
    binary=repo/'bazel-bin'/testpath
    passed=run.returncode==0 and rows==expected
    result=dict(schema=1,status='real_xla_control_order_relaxation_reproduced' if passed else 'replay_failed',
                source_commit=COMMIT,pass_source_sha256=PASS_SHA,command=command,
                xla_full_pass_run=any(m=='pass' for _,m,*_ in rows),xla_handler_run=bool(rows),
                native_schedule_verified=True if passed else False,custom_call_callbacks=True if passed else False,
                execution_scope='native verified HloSchedules; per-instruction HloEvaluator with cached substitutions; mock synchronous effects',
                test_passed=passed,exit_code=run.returncode,elapsed_seconds=elapsed,
                binary_sha256=digest(binary) if binary.exists() else None,
                cases=[dict(name=n,mode=m,changed=c=='1',reachable_before=b=='1',reachable_after=a=='1',reverse_before=rb=='1',reverse_after=ra=='1',forward_trace=f,reverse_trace=r,actors_retained=True,verified=True)
                       for n,m,c,b,a,rb,ra,f,r in rows],
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in sorted(out.iterdir()) if p.is_file()])
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('status', 'exit_code', 'test_passed', 'elapsed_seconds')}, indent=2))
    print((out / 'build.log').read_text()[-12000:])
    if not passed:
        raise SystemExit(run.returncode or 1)


if __name__ == '__main__':
    main()
