"""Execute and archive a fresh PRED guard replay against the pinned real XLA pass."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time

ROOT = Path(__file__).resolve().parents[1]
TARGET = '//xla/hlo/transforms/simplifiers:pred_constant_guard_replay_test'
PASS_SHA = '1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f'
COMMIT = 'e58e523b11f1fde802a493a776d158007486e1bf'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', required=True, help='new reports/ directory basename')
    args = parser.parse_args()
    if not re.fullmatch(r'pred-guard-replay-v[0-9]+', args.archive):
        raise ValueError('archive must be an explicit pred-guard-replay-vN basename')
    out = ROOT / 'reports' / args.archive
    if out.exists():
        raise ValueError('refusing to overwrite an existing archive')
    repo = ROOT / 'external/xla'
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip() == COMMIT
    pass_source = repo / 'xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert digest(pass_source) == PASS_SHA
    fixture = ROOT / 'tests/xla/pred_constant_guard_replay_test.cc'
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
    testpath = 'xla/hlo/transforms/simplifiers/pred_constant_guard_replay_test'
    for name in ('test.log', 'test.xml'):
        path = repo / 'bazel-testlogs' / testpath / name
        if path.exists():
            shutil.copyfile(path, out / name)
    log = (out / 'test.log').read_text() if (out / 'test.log').exists() else ''
    rows = re.findall(r'^PRED_GUARD_RESULT wrapper=(\w+) expected_changed=([01]) changed=([01]) before_after_equal=1 root_parameter=([01])$', log, re.M)
    expected_names={'literal','broadcast','copy','dynamic_slice','reshape','reverse','slice','transpose','opaque_not','nonuniform'}
    boundary='PRED_GUARD_LITERAL empty_matches_both=1 mixed_matches_neither=1 ones_only_one=1 value_two_rejected=1' in log
    valid=len(rows)==10 and {r[0] for r in rows}==expected_names and all(e==c==p==('0' if n in ('opaque_not','nonuniform') else '1') for n,e,c,p in rows)
    binary = repo / 'bazel-bin' / testpath
    passed = run.returncode == 0 and valid and boundary
    result = dict(schema=1, status='real_xla_pred_guard_handler_and_literal_controls_passed' if passed else 'replay_failed',
                  source_commit=COMMIT, pass_source_sha256=PASS_SHA, command=command,
                  xla_handler_run=bool(rows), xla_full_pass_run=False, test_passed=passed,
                  native_scope='direct public HandleAnd call preserves producer wrappers; LiteralBase::IsAll boundary checks',
                  exit_code=run.returncode, elapsed_seconds=elapsed,
                  binary_sha256=digest(binary) if binary.exists() else None,
                  cases=[dict(wrapper=n, expected_changed=e=='1', changed=c=='1', root_parameter=p=='1', before_after_equal=True)
                         for n,e,c,p in rows], literal_boundary_control_passed=boundary,
                  files=[dict(path=str(p.relative_to(ROOT)), sha256=digest(p))
                         for p in sorted(out.iterdir()) if p.is_file()])
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('status', 'exit_code', 'test_passed', 'elapsed_seconds')}, indent=2))
    print((out / 'build.log').read_text()[-12000:])
    if not passed:
        raise SystemExit(run.returncode or 1)


if __name__ == '__main__':
    main()
