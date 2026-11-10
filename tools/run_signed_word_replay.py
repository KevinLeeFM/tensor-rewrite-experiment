"""Execute and archive a fresh modular arithmetic replay against the pinned real XLA pass."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import time
from signed_word_cases import expected_rows

ROOT = Path(__file__).resolve().parents[1]
TARGET = '//xla/hlo/transforms/simplifiers:signed_word_replay_test'
PASS_SHA = '1ecfd7d4ba958ac0e795d8663c14f7f6b1ebd147a8a83ed0e99661740105628f'
COMMIT = 'e58e523b11f1fde802a493a776d158007486e1bf'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--archive', required=True, help='new reports/ directory basename')
    args = parser.parse_args()
    if not re.fullmatch(r'signed-word-replay-v[0-9]+', args.archive):
        raise ValueError('archive must be an explicit signed-word-replay-vN basename')
    out = ROOT / 'reports' / args.archive
    if out.exists():
        raise ValueError('refusing to overwrite an existing archive')
    repo = ROOT / 'external/xla'
    assert subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=repo, text=True).strip() == COMMIT
    pass_source = repo / 'xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert digest(pass_source) == PASS_SHA
    fixture = ROOT / 'tests/xla/signed_word_replay_test.cc'
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
    testpath = 'xla/hlo/transforms/simplifiers/signed_word_replay_test'
    for name in ('test.log', 'test.xml'):
        path = repo / 'bazel-testlogs' / testpath / name
        if path.exists():
            shutil.copyfile(path, out / name)
    log = (out / 'test.log').read_text() if (out / 'test.log').exists() else ''
    rows=re.findall(r'^SIGNED_WORD_RESULT dtype=(s8|s16|s32|s64) case=(\w+) mode=(control|handler|pass) changed=([01]) checked=(\d+) values=([0-9,]+) signed=([-0-9,]+) rewritten_verified=1$',log,re.M)
    expected=expected_rows()
    binary=repo/'bazel-bin'/testpath
    passed=run.returncode==0 and rows==expected
    result=dict(schema=1,status='real_xla_signed_word_overflow_and_narrowing_preserved' if passed else 'replay_failed',
                source_commit=COMMIT,pass_source_sha256=PASS_SHA,command=command,
                xla_full_pass_run=any(m=='pass' for _,_,m,*_ in rows),xla_handler_run=bool(rows),
                native_operator_evaluation=True if passed else False,
                execution_scope='s8/s16/s32/s64 words and signed observations; typed 64-bit intermediate arithmetic; native HloEvaluator; no floating or whole-source graph claim',
                test_passed=passed,exit_code=run.returncode,elapsed_seconds=elapsed,
                binary_sha256=digest(binary) if binary.exists() else None,
                cases=[dict(dtype=d,name=n,mode=m,changed=c=='1',checked=int(k),values=list(map(int,v.split(','))),signed_values=list(map(int,si.split(','))),rewritten_verified=True)
                       for d,n,m,c,k,v,si in rows],
                files=[dict(path=str(p.relative_to(ROOT)),sha256=digest(p)) for p in sorted(out.iterdir()) if p.is_file()])
    (out / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({k: result[k] for k in ('status', 'exit_code', 'test_passed', 'elapsed_seconds')}, indent=2))
    print((out / 'build.log').read_text()[-12000:])
    if not passed:
        raise SystemExit(run.returncode or 1)


if __name__ == '__main__':
    main()
