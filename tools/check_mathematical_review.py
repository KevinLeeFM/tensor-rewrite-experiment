"""Validate review-packet integrity and the limits of a clean mathematical project replay."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

import freeze_mathematical_review as packet
from replay_mathematical import STEPS, RESULTS

ROOT=Path(__file__).resolve().parents[1]
REPLAY='reports/mathematical-clean-replay-v1.json'
DESCRIPTOR='reviews/packets/mathematical-foundation-v1.json'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def committed(revision,path,root=ROOT):
    return json.loads(subprocess.check_output(['git','show',revision+':'+path],cwd=root))


def validate_replay(record,root=ROOT):
    assert record['status']=='passed_clean_project_replay_with_shared_pinned_dependencies'
    assert record['project_build_outputs_initially_absent'] is True
    assert record['project_artifacts_copied'] is False
    assert record['independent_semantic_review_performed'] is False
    assert record['code_correspondence_performed'] is False
    assert record['code_correspondence_future_work'] is True
    assert record['whole_workload_verdict']=='still_open'
    assert [(s['name'],s['command']) for s in record['steps']]==STEPS
    assert all(s['exit_code']==0 for s in record['steps'])
    for step in record['steps']:
        assert sha(root/step['log'])==step['log_sha256'],step['name']
    comparisons=record['result_comparisons']
    assert [c['path'] for c in comparisons]==RESULTS
    assert all(c['full_json_equality'] is True and c['expected_json_sha256']==c['actual_json_sha256']
               for c in comparisons)
    for comparison in comparisons:
        expected=committed(record['source_revision'],comparison['path'],root)
        expected_sha=hashlib.sha256(json.dumps(expected,sort_keys=True).encode()).hexdigest()
        assert comparison['expected_json_sha256']==expected_sha,comparison['path']
    test_counts={}
    for name,expected_count in [('convolution_tests',16),('logical_tests',4),('ledger_tests',3)]:
        step=next(s for s in record['steps'] if s['name']==name)
        counts=re.findall(r'^Ran (\d+) tests? in ',(root/step['log']).read_text(),re.M)
        assert counts==[str(expected_count)],(name,counts)
        test_counts[name]=int(counts[0])
    assert record['packages_before']==record['packages_after']
    dependencies=committed(record['source_revision'],'lake-manifest.json',root)
    assert [(p['name'],p['revision']) for p in record['packages_before']]==[
        (p['name'],p['rev']) for p in dependencies['packages']]
    assert all(p['tracked_sources_clean'] for p in record['packages_before'])
    theory=committed(record['source_revision'],'reports/theory-progress.json',root)
    ledger=committed(record['source_revision'],'census/mathematical-ledger.json',root)
    assert record['checked_theory_statements']==theory['new_theorem_count']==89
    assert record['custom_lean_lines']==theory['total_custom_lean_lines']==4165
    assert record['registered_declarations']==ledger['distinct_checked_declarations']==319
    assert record['benchmark_record_count']==ledger['benchmark_record_count']==488
    assert record['whole_benchmark_records_closed']==ledger['whole_benchmark_records_closed']==0
    assert record['mathematical_obligation_denominator'] is None
    assert ledger['mathematical_obligation_denominator'] is None
    return test_counts



def observe_checkout(replay):
    path=ROOT/'reports/mathematical-clean-replay-v1-observations.json'
    if not path.exists():
        checkout=Path(replay['checkout'])
        revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=checkout,text=True).strip()
        assert revision==replay['source_revision']
        changed=subprocess.check_output(['git','diff','--name-only'],cwd=checkout,text=True).splitlines()
        assert set(changed)<={'reports/library-setup-build.log','reports/theory-build.log'}
        log=ROOT/'reports/mathematical-clean-replay-v1-logs/cold-project-build.log'
        log.write_bytes((checkout/'reports/library-setup-build.log').read_bytes())
        built=re.findall(r'Built (TensorRewrite[A-Za-z0-9_.]*) ',log.read_text())
        tracked=subprocess.check_output(['git','ls-tree','-r','--name-only',revision],cwd=ROOT,text=True)
        modules=[p[:-5].replace('/','.') for p in tracked.splitlines()
                 if p.endswith('.lean') and (p.startswith('TensorRewrite/') or p in
                    ('TensorRewrite.lean','TensorRewriteLibraries.lean','TensorRewriteTheory.lean'))]
        assert set(modules)-set(built)=={'TensorRewrite.Pilot.Audit'}
        assert sorted(built)==sorted(m for m in modules if m!='TensorRewrite.Pilot.Audit')
        audit_source=(checkout/'TensorRewrite/Pilot/Audit.lean').read_text()
        assert all(not line.strip() or line=='import TensorRewrite' or
                   line.startswith('#print axioms ') for line in audit_source.splitlines())
        audit=subprocess.run(['lake','env','lean','TensorRewrite/Pilot/Audit.lean'],
                             cwd=checkout,text=True,capture_output=True)
        audit_log=ROOT/'reports/mathematical-clean-replay-v1-logs/standalone-pilot-audit.log'
        audit_log.write_text(audit.stdout+audit.stderr)
        assert audit.returncode==0,audit.stdout+audit.stderr
        observation=dict(source_revision=revision,tracked_changes=changed,
                         mathematical_sources_unchanged=True,
                         standalone_audit_not_a_default_build_target='TensorRewrite/Pilot/Audit.lean',
                         standalone_audit_exit_code=audit.returncode,
                         standalone_audit_log=str(audit_log.relative_to(ROOT)),
                         standalone_audit_log_sha256=sha(audit_log),
                         cold_build_log=str(log.relative_to(ROOT)),cold_build_log_sha256=sha(log),
                         built_project_modules=sorted(built),built_project_module_count=len(built))
        path.write_text(json.dumps(observation,indent=2)+'\n')
    observation=json.loads(path.read_text())
    assert observation['source_revision']==replay['source_revision']
    assert observation['mathematical_sources_unchanged'] is True
    assert observation['standalone_audit_exit_code']==0
    assert sha(ROOT/observation['standalone_audit_log'])==observation['standalone_audit_log_sha256']
    assert set(observation['tracked_changes'])<={
        'reports/library-setup-build.log','reports/theory-build.log'}
    assert sha(ROOT/observation['cold_build_log'])==observation['cold_build_log_sha256']
    observed=re.findall(r'Built (TensorRewrite[A-Za-z0-9_.]*) ',
                        (ROOT/observation['cold_build_log']).read_text())
    assert sorted(observed)==observation['built_project_modules']
    assert len(observed)==observation['built_project_module_count']==105
    return observation,path


def main():
    packet.verify()
    descriptor=json.loads((ROOT/DESCRIPTOR).read_text())
    replay=json.loads((ROOT/REPLAY).read_text());test_counts=validate_replay(replay)
    assert descriptor['source_revision']==replay['source_revision']
    manifest=json.loads((ROOT/descriptor['manifest']).read_text())
    assert sorted(f['path'] for f in manifest['files'])==sorted(
        packet.selection(descriptor['source_revision'])+[packet.BRIEF])
    for file in manifest['files']:
        if file['origin']=='committed_mathematical_snapshot':
            content=subprocess.check_output(['git','show',descriptor['source_revision']+':'+file['path']],cwd=ROOT)
            assert hashlib.sha256(content).hexdigest()==file['sha256'],file['path']
    observation,observation_path=observe_checkout(replay)
    result=dict(schema=1,status='frozen_math_packet_and_clean_project_replay_ready_for_review',
                source_revision=replay['source_revision'],packet_descriptor=DESCRIPTOR,
                packet_descriptor_sha256=sha(ROOT/DESCRIPTOR),
                replay_report=REPLAY,replay_report_sha256=sha(ROOT/REPLAY),
                orchestration_files=[dict(path=p,sha256=sha(ROOT/p)) for p in
                    ('tools/replay_mathematical.py','tools/freeze_mathematical_review.py',
                     'tools/check_mathematical_review.py')],
                independent_semantic_review_performed=False,review_outcome='pending',
                project_outputs_rebuilt_in_clean_checkout=True,
                cold_built_project_modules=observation['built_project_module_count'],
                replay_observations=str(observation_path.relative_to(ROOT)),
                replay_observations_sha256=sha(observation_path),
                dependency_cache_reused=True,upstream_libraries_rebuilt_from_scratch=False,
                full_json_results_reproduced=9,mathematical_tests_replayed=sum(test_counts.values()),
                replayed_test_counts=test_counts,
                checked_theory_statements=89,registered_declarations=319,custom_lean_lines=4165,
                benchmark_record_count=488,whole_benchmark_records_closed=0,
                mathematical_obligation_denominator=None,whole_workload_verdict='still_open',
                code_correspondence_performed=False,code_correspondence_future_work=True)
    (ROOT/'reports/mathematical-review-readiness-v1.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Mathematical review ready: frozen packet,12 replay stages,9 exact JSON reproductions; '
          'independent semantics and full-workload verdict remain pending.')


if __name__=='__main__':main()
