"""Replay committed mathematical evidence with fresh project outputs and pinned shared dependencies.

Only explicitly listed mathematical checks run. Source extraction and native pass tools are excluded.
A clean checkout replay by the integrator is not an independent semantic statement review.
"""
import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import time

ROOT=Path(__file__).resolve().parents[1]
STEPS=[
    ('libraries',['python3','tools/check_libraries.py']),
    ('theory',['python3','tools/check_theory.py']),
    ('logical_family',['python3','tools/check_logical_family.py']),
    ('convolution_base',['python3','tools/check_convolution_model.py']),
    ('convolution_pointwise',['python3','tools/check_convolution_pointwise.py']),
    ('convolution_dot',['python3','tools/check_convolution_dot.py']),
    ('convolution_separable',['python3','tools/check_convolution_separable.py']),
    ('convolution_ordered',['python3','tools/check_convolution_ordered.py']),
    ('mathematical_ledger',['python3','tools/mathematical_ledger.py']),
    ('convolution_tests',['python3','-m','unittest','discover','-s','tests','-p','test_convolution*.py','-v']),
    ('logical_tests',['python3','-m','unittest','discover','-s','tests','-p','test_logical_family.py','-v']),
    ('ledger_tests',['python3','-m','unittest','discover','-s','tests','-p','test_mathematical_ledger.py','-v']),
]
RESULTS=['reports/library-setup.json','reports/theory-progress.json','reports/logical-values-family.json',
         'reports/convolution-model.json','reports/convolution-pointwise.json',
         'reports/convolution-dot.json','reports/convolution-separable.json',
         'reports/convolution-ordered.json','census/mathematical-ledger.json']


def run(command,cwd):
    return subprocess.run(command,cwd=cwd,text=True,capture_output=True)


def require(command,cwd):
    result=run(command,cwd)
    assert result.returncode==0,result.stdout+result.stderr
    return result.stdout.strip()


def sha(data):return hashlib.sha256(data).hexdigest()


def packages(root):
    manifest=json.loads((root/'lake-manifest.json').read_text())
    result=[]
    for package in manifest['packages']:
        path=root/'.lake/packages'/package['name']
        revision=require(['git','rev-parse','HEAD'],path)
        changes=require(['git','status','--porcelain','--untracked-files=no'],path)
        assert revision==package['rev'] and changes=='',package['name']
        result.append(dict(name=package['name'],revision=revision,tracked_sources_clean=True))
    return result


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ref',required=True,help='Committed mathematical snapshot to replay')
    parser.add_argument('--report',default='reports/mathematical-clean-replay-v1.json')
    args=parser.parse_args()
    revision=require(['git','rev-parse',args.ref+'^{commit}'],ROOT)
    report_path=ROOT/args.report
    assert not report_path.exists(),'new replay attempts need a distinct report name'
    logs=ROOT/'reports'/ (report_path.stem+'-logs')
    assert not logs.exists()
    logs.mkdir()
    checkout=Path(tempfile.mkdtemp(prefix='tensor-math-replay-'))
    # The temporary root starts empty; local object sharing does not copy build outputs.
    require(['git','clone','--shared','--no-checkout',str(ROOT),str(checkout)],ROOT)
    require(['git','checkout','--detach',revision],checkout)
    assert require(['git','status','--porcelain'],checkout)==''
    assert not (checkout/'.lake').exists()
    (checkout/'.lake').mkdir()
    (checkout/'.lake/packages').symlink_to((ROOT/'.lake/packages').resolve(),target_is_directory=True)
    assert not (checkout/'.lake/build').exists()
    package_state=packages(checkout)
    expected={name:json.loads(require(['git','show',revision+':'+name],ROOT)) for name in RESULTS}
    record=dict(schema=1,status='replay_running',source_revision=revision,checkout=str(checkout),
                started_at=datetime.now(timezone.utc).isoformat(),
                project_build_outputs_initially_absent=True,project_artifacts_copied=False,
                dependencies='shared pinned source/compiled cache; upstream libraries not rebuilt from scratch',
                packages_before=package_state,lean_version=require(['lean','--version'],checkout),
                python_version=require(['python3','--version'],checkout),steps=[],result_comparisons=[],
                independent_semantic_review_performed=False,code_correspondence_performed=False,
                code_correspondence_future_work=True,whole_workload_verdict='still_open')
    def save():report_path.write_text(json.dumps(record,indent=2)+'\n')
    save()
    for name,command in STEPS:
        started=time.monotonic()
        result=run(command,checkout)
        log=logs/(name+'.log');log.write_text(result.stdout+result.stderr)
        record['steps'].append(dict(name=name,command=command,exit_code=result.returncode,
                                    elapsed_seconds=round(time.monotonic()-started,3),
                                    log=str(log.relative_to(ROOT)),log_sha256=sha(log.read_bytes())))
        if result.returncode:
            record['status']='replay_failed';save()
            raise SystemExit(name+': '+(result.stdout+result.stderr)[-2000:])
        save();print('Passed '+name,flush=True)
    for name,wanted in expected.items():
        actual=json.loads((checkout/name).read_text())
        equal=actual==wanted
        record['result_comparisons'].append(dict(path=name,full_json_equality=equal,
            expected_json_sha256=sha(json.dumps(wanted,sort_keys=True).encode()),
            actual_json_sha256=sha(json.dumps(actual,sort_keys=True).encode())))
        if not equal:
            record['status']='replay_result_mismatch';save()
            raise SystemExit('Reproduced result differs: '+name)
    record['packages_after']=packages(checkout)
    assert record['packages_after']==package_state
    theory=expected['reports/theory-progress.json'];ledger=expected['census/mathematical-ledger.json']
    record['checked_theory_statements']=theory['new_theorem_count']
    record['custom_lean_lines']=theory['total_custom_lean_lines']
    record['registered_declarations']=ledger['distinct_checked_declarations']
    record['benchmark_record_count']=ledger['benchmark_record_count']
    record['whole_benchmark_records_closed']=ledger['whole_benchmark_records_closed']
    record['mathematical_obligation_denominator']=ledger['mathematical_obligation_denominator']
    record['status']='passed_clean_project_replay_with_shared_pinned_dependencies'
    record['completed_at']=datetime.now(timezone.utc).isoformat();save()
    print('Clean project replay passed; '+str(len(RESULTS))+' complete JSON results reproduced.',flush=True)


if __name__=='__main__':main()
