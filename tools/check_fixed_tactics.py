"""Validate saved fixed-policy evidence and account for comparison code without changing core coverage."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import subprocess
import run_fixed_tactics as run
from lean_size import count_source

ROOT=run.ROOT
PACKET=run.PACKET
PREREG='be93b376d74e7a1d84609de3245816d86f741845'
ALLOWED=run.ALLOWED


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()
def read(path):return json.loads((ROOT/path).read_text())


def verify_registration():
    manifest=read(run.MANIFEST)
    revision=subprocess.check_output(['git','rev-parse',PREREG],cwd=ROOT,text=True).strip()
    frozen_manifest=subprocess.check_output(['git','show',revision+':'+run.MANIFEST],cwd=ROOT)
    assert frozen_manifest==(ROOT/run.MANIFEST).read_bytes()
    for row in manifest['files']:
        registered=subprocess.check_output(['git','show',revision+':'+row['path']],cwd=ROOT)
        assert hashlib.sha256(registered).hexdigest()==row['sha256'],row['path']
        # Packet and automation are immutable. Other project files are historical
        # provenance at the preregistered revision, including the evolving ledger.
        if row['path'].startswith((PACKET+'/', 'TensorRewrite/Comparisons/')) or row['path']=='tools/run_fixed_tactics.py':
            assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert manifest['measured_targets']==44 and manifest['reviewed_foundation_targets']==89
    assert manifest['whole_workload_compared'] is False
    assert manifest['independent_comparison_review'] is False
    return manifest,revision


def validate_summary(result):
    manifest,revision=verify_registration()
    assert result['status']=='completed_fixed_tactic_subset_comparison'
    assert result['manifest']==run.MANIFEST and result['manifest_sha256']==digest(ROOT/run.MANIFEST)
    assert result['selected_targets']==44 and result['excluded_reviewed_targets']==45
    assert result['target_policy_attempts']==176 and result['negative_tactic_controls']==8
    assert result['agent_replay_targets']==44 and result['historical_solution_informed_agent_replay'] is True
    for flag in ('fresh_blinded_agent_comparison','whole_workload_compared',
                 'independent_comparison_review','code_correspondence_performed'):
        assert result[flag] is False,flag
    targets=read(PACKET+'/targets.json')['targets'];policies=read(PACKET+'/policies.json')
    expected={(r['id'],p['id']) for r in targets for p in policies['policies']}
    negative={(r,p['id']) for r in ('invalid_nat','invalid_int') for p in policies['policies']}
    seen=set();accepted=[]
    for row in result['attempts']:
        pair=(row['target'],row['policy']);assert pair not in seen;seen.add(pair)
        assert pair in (negative if row['negative_control'] else expected)
        for field in ('source','log'):assert digest(ROOT/row[field])==row[field+'_sha256'],row[field]
        output=(ROOT/row['log']).read_text()
        assert 'FIXED_BASELINE_GUARD absent=835 present=0' in output,row['log']
        actual=dict(returncode=row['returncode'],stdout=output,timeout=row['timeout'])
        assert run.classify(actual)==row['status']
        if row['status']=='kernel_checked':
            assert row['negative_control'] is False
            assert row['axioms']==run.axioms(output,run.CANDIDATE)
            assert set(row['axioms'])<=ALLOWED
            accepted.append(row)
    assert seen==expected|negative and len(result['attempts'])==184
    assert result['outcome_counts']==dict(Counter(r['status'] for r in result['attempts']))
    assert result['accepted_by_policy']=={p['id']:sum(r['policy']==p['id'] for r in accepted)
                                           for p in policies['policies']}
    assert result['union_accepted_targets']==len({r['target'] for r in accepted})
    preflight={r['id']:r for r in result['preflight']}
    assert set(preflight)=={'build','basis','signatures','agent','policy_smoke','leak_negative','signature_negative'}
    for name,row in preflight.items():
        assert row['returncode']==(1 if name.endswith('_negative') else 0) and not row['timeout']
    agent=(ROOT/(PACKET+'/results/agent.log')).read_text()
    assert 'FIXED_BASELINE_GUARD absent=835 present=0' in agent and 'SIGNATURES exact=44' in agent
    for row in targets:run.axioms(agent,row['original'])
    assert 'FIXED_BASELINE_LEAK' in (ROOT/(PACKET+'/results/leak_negative.log')).read_text()
    assert 'FIXED_BASELINE_SIGNATURE_MISMATCH' in (ROOT/(PACKET+'/results/signature_negative.log')).read_text()
    # The original eight controls failed to parse, so they are not evidence of
    # false-goal rejection. Require the separately versioned syntax-only repair.
    repaired=read(PACKET+'/negative-repair-v2/results.json')
    repair_manifest=read(PACKET+'/negative-repair-v2/manifest.json')
    assert repaired['status']=='all_eight_corrected_false_proposition_controls_rejected'
    assert repaired['manifest_sha256']==digest(ROOT/(PACKET+'/negative-repair-v2/manifest.json'))
    assert repaired['measured_attempts_changed'] is False and repaired['policies_changed'] is False
    assert repaired['original_bad_control_trials_preserved'] is True
    assert repair_manifest['original_summary_sha256']==digest(ROOT/(PACKET+'/results/summary.json'))
    assert repair_manifest['measured_attempts_unchanged']==176
    assert repair_manifest['policies_and_selected_statements_unchanged'] is True
    for row in repair_manifest['files']:assert digest(ROOT/row['path'])==row['sha256']
    assert {(r['target'],r['policy']) for r in repaired['controls']}==negative
    for row in repaired['controls']:
        assert row['status']=='fixed_tactic_unsuccessful' and row['returncode']!=0 and not row['timeout']
        for field in ('source','log'):assert digest(ROOT/row[field])==row[field+'_sha256']
        output=(ROOT/row['log']).read_text()
        assert run.classify(dict(stdout=output,returncode=row['returncode'],timeout=False))==row['status']
        assert 'FIXED_BASELINE_GUARD absent=835 present=0' in output
    for values in repaired['refutation_axioms'].values():assert set(values)<=ALLOWED
    assert {r['status'] for r in result['attempts'] if r['negative_control']}=={'infrastructure_failure'}
    assert not any(r['status']=='infrastructure_failure' for r in result['attempts'] if not r['negative_control'])
    return accepted,targets,policies,revision


def measure(path):
    text=(ROOT/path).read_text();return dict(path=path,sha256=digest(ROOT/path),**count_source(text))


def main():
    result=read(PACKET+'/results/summary.json')
    accepted,targets,policies,revision=validate_summary(result)
    indexed={r['id']:r for r in targets}
    shared=[measure('TensorRewrite/Comparisons/'+name+'.lean') for name in
            ('FixedTacticsStatements','FixedTacticsPolicies','FixedTacticsGuard')]
    agent=measure(PACKET+'/AgentReplay.lean')
    policy_details=[]
    for policy in policies['policies']:
        rows=[r for r in accepted if r['policy']==policy['id']]
        policy_details.append(dict(policy=policy['id'],accepted=len(rows),attempted=44,
            accepted_by_group=dict(Counter(indexed[r['target']]['original'].split('.')[-2] for r in rows)),
            accepted_trial_whole_module_lines=sum(measure(r['source'])['code_lines'] for r in rows),
            matched_reference_declaration_lines=sum(count_source(indexed[r['target']]['reference_declaration'])['code_lines'] for r in rows),
            matched_reference_body_lines=sum(count_source(indexed[r['target']]['reference_body'])['code_lines'] for r in rows)))
    accepted_sources=[measure(r['source']) for r in accepted]
    failed_sources=[measure(r['source']) for r in result['attempts'] if r['status']!='kernel_checked']
    controls=[measure(PACKET+'/'+name+'.lean') for name in
              ('BasisAudit','SignatureAudit','LeakNegativeControl','SignatureNegativeControl','PolicySmoke')]
    union={r['target'] for r in accepted}
    reference_rows=[dict(id=r['id'],original=r['original'],fixed_policy_success=r['id'] in union,
                         reference_declaration_lines=count_source(r['reference_declaration'])['code_lines'],
                         reference_body_lines=count_source(r['reference_body'])['code_lines']) for r in targets]
    repair_controls=[measure(PACKET+'/negative-repair-v2/Refutations.lean')]
    repair_trials=[measure(r['source']) for r in read(PACKET+'/negative-repair-v2/results.json')['controls']]
    inventory=[measure(str(p.relative_to(ROOT))) for directory in
               [ROOT/'TensorRewrite/Comparisons',ROOT/PACKET]
               for p in directory.rglob('*.lean')]
    analysis=dict(status='validated_frozen_reviewed_subset_fixed_tactic_comparison',preregistration_revision=revision,
        main_campaign_lean_lines_at_registration=10497,main_campaign_theory_statements_unchanged=575,
        comparison_shared_lean_modules=shared,comparison_shared_statement_lines=shared[0]['code_lines'],
        comparison_shared_automation_lines=sum(r['code_lines'] for r in shared[1:]),
        historical_agent_replay=agent,reference_agent_target_count=44,
        policy_details=policy_details,union_fixed_policy_success=len(union),
        union_fixed_policy_residuals=44-len(union),reference_rows=reference_rows,
        all_accepted_trial_module_lines=sum(r['code_lines'] for r in accepted_sources),
        all_failed_and_negative_trial_lines=sum(r['code_lines'] for r in failed_sources),
        control_module_lines=sum(r['code_lines'] for r in controls),
        repaired_negative_trial_lines=sum(r['code_lines'] for r in repair_trials),
        false_proposition_refutation_control_lines=sum(r['code_lines'] for r in repair_controls),
        additional_comparison_lean_files=len(inventory),
        additional_comparison_lean_source_inventory_lines=sum(r['code_lines'] for r in inventory),
        additional_comparison_lean_inventory=inventory,
        comparison_inventory_is_accepted_unique_development=False,
        accepted_sources=accepted_sources,failed_sources=failed_sources,controls=controls,
        original_negative_control_infrastructure_failures=8,repaired_well_formed_negative_rejections=8,
        measured_targets_and_policies_unchanged_by_control_repair=True,
        comparison_new_unique_mathematical_coverage=0,comparison_changes_workload_denominator=False,
        agent_replay_is_historical_solution_informed=True,minimum_proof_size_estimated=False,
        blinded_agent_discovery_measured=False,independent_comparison_review=False,
        whole_workload_compared=False,code_correspondence_performed=False,
        summary_sha256=digest(ROOT/(PACKET+'/results/summary.json')),
        accounting_boundary='Core accepted development, common comparison input/automation, historical replay duplication, accepted fixed-trial modules and failed/control source are separate views; do not infer an efficiency ordering from unequal accepted target sets.')
    (ROOT/'reports/fixed-tactics-comparison-v1.json').write_text(json.dumps(analysis,indent=2)+'\n')
    print('Validated',len(union),'/44 fixed-policy union; historical agent replay44/44. '
          'Core coverage unchanged; comparison is not blinded or whole-workload evidence.')


if __name__=='__main__':main()
