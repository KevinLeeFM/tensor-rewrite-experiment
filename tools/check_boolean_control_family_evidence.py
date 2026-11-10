"""Validate the Boolean-family ordering diagnosis and keep repair claims scoped."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
RULES=('and_rhs_true','and_lhs_true','and_rhs_false','and_lhs_false',
       'or_rhs_true','or_lhs_true','or_rhs_false','or_lhs_false',
       'xor_rhs_false','xor_lhs_false','xor_self','not_not')
IDS=('HandleAnd/rhs-true','HandleAnd/lhs-true','HandleAnd/rhs-zero','HandleAnd/lhs-zero',
     'HandleOr/rhs-true','HandleOr/lhs-true','HandleOr/rhs-zero','HandleOr/lhs-zero',
     'HandleXor/rhs-zero','HandleXor/lhs-zero','HandleXor/equal-inputs','HandleNot/involution')
SCOPE='native verified HloSchedules; per-instruction HloEvaluator with cached substitutions; mock synchronous effects'
REPAIR='test-only added A-to-B control dependency after full pass; no canonical pass modification or general source repair proof'
RULE_SCOPE='twelve scalar PRED pilot branches; pointer-identical Xor subcase; discarded operand/inner Not carries A control prerequisite'


def check_contract(root=ROOT):
    contract=json.loads((root/'census/boolean-control-family-contract.json').read_text())
    assert contract['status']=='native_boolean_family_order_diagnosis_not_full_source_acceptance'
    assert contract['accepted_source_rewrites']==0
    assert contract['all_schedule_refinement_proved'] is False
    assert contract['production_backend_executed'] is False
    assert contract['native_scope']==SCOPE and contract['repair_scope']==REPAIR
    assert contract['rule_scope']==RULE_SCOPE and contract['expected_native_runs']==144
    assert contract['native_evidence']=='reports/boolean-control-family-replay-v3/result.json'
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert contract==proofs['boolean_control_family']
    assert [r['native_rule'] for r in contract['source_cases']]==list(RULES)
    assert [r['source_case'] for r in contract['source_cases']]==list(IDS)
    cases={c['id']:c for c in json.loads((root/'census/simple-cases.json').read_text())['cases']}
    source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    fixed={r['source_case']:r['theorem'] for r in proofs['effectful_graph_context']['rules']}
    for row in contract['source_cases']:
        case=cases[row['source_case']]
        assert row['source_line']==case['line'] and row['source_end_line']==case['end_line']
        body='\n'.join(source[case['line']-1:case['end_line']]).encode()
        assert hashlib.sha256(body).hexdigest()==row['source_body_sha256']
        assert row['status']=='native_dependency_order_loss_observed_effect_contract_review_pending'
        assert row['accepted_source_proof'] is None and row['cpp_extraction_proved'] is False
        assert row['related_fixed_schedule_theorem']==fixed[row['source_case']]
        assert case['proof'] is None
    assert contract['support_theorems']==['TensorRewrite.Pilot.DependencyOrder.Graph.isSchedule_of_predecessor_inclusion',
        'TensorRewrite.Pilot.DependencyOrder.Graph.isTrace_of_predecessor_inclusion']
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    assert contract['repair_certificates']==['TensorRewrite.Pilot.ControlOrder.'+n for n in
        ('repaired_forward_valid','repaired_requires_forward','repaired_reverse_impossible',
         'repaired_refines_replacement','repaired_forward_trace')]
    assert [f['path'] for f in contract['failed_archives']]==[
        'reports/boolean-control-family-replay-v1/result.json','reports/boolean-control-family-replay-v2/result.json']


def check_files(root,folder,result):
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']


def check_archive(root=ROOT):
    folder=root/'reports/boolean-control-family-replay-v3'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_boolean_family_discarded_prerequisites_reproduced'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run']
    assert result['native_schedule_verified'] and result['custom_call_callbacks']
    assert result['execution_scope']==SCOPE and '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    check_files(root,folder,result)
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^BOOLEAN_CONTROL_RESULT rule=(\w+) profile=(\w+) mode=(control|handler|pass|repair) changed=([01]) reachable_before=([01]) reachable_after=([01]) reverse_before=([01]) reverse_after=([01]) repaired=([01]) forward_trace=(A,B) reverse_trace=(B,A|invalid) actors_retained=1 verified=1$',log,re.M)
    expected=[]
    for name in RULES:
        for profile in ('discarded_control','old_control','no_successor'):
            for mode in ('control','handler','pass','repair'):
                successor=profile!='no_successor'
                changed=mode!='control' and (profile!='old_control' or name=='xor_self')
                after=successor and (not changed or profile=='old_control' or mode=='repair')
                repaired=mode=='repair' and profile=='discarded_control'
                expected.append((name,profile,mode,str(int(changed)),str(int(successor)),str(int(after)),str(int(not successor)),str(int(not after)),str(int(repaired)),'A,B','invalid' if after else 'B,A'))
    assert rows==expected and len(rows)==144
    assert result['cases']==[dict(rule=n,profile=p,mode=m,changed=c=='1',reachable_before=b=='1',reachable_after=a=='1',reverse_before=rb=='1',reverse_after=ra=='1',repaired=rp=='1',forward_trace=f,reverse_trace=r,actors_retained=True,verified=True) for n,p,m,c,b,a,rb,ra,rp,f,r in rows]
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    # Failed attempts remain failed. The second archive contains a passing test
    # whose output did not satisfy the stricter complete-row evidence gate.
    for number,code in ((1,3),(2,0)):
        prior=root/('reports/boolean-control-family-replay-v'+str(number))
        failed=json.loads((prior/'result.json').read_text())
        assert failed['status']=='replay_failed' and failed['test_passed'] is False
        assert failed['exit_code']==code
        check_files(root,prior,failed)
    model=json.loads((root/'reports/pilot-values.json').read_text())
    assert model['accepted_source_rewrites']==0 and model['checked_control_order_repair_certificates']==5
    assert model['checks']['control_repair_controls']==dict(exit_code=0,stdout='ORDER_REPAIR_MODEL reverse_before=true reverse_after=false forward_after=true\n',stderr='')
    invalid=model['checks']['invalid_control_repair']
    assert invalid['exit_code']!=0 and 'rfl' in invalid['stdout']+invalid['stderr']


if __name__=='__main__':
    check_contract();check_archive()
    print('All 12 Boolean pilot branches reproduce discarded-prerequisite order loss in 144 native runs; test-only edge repair and scope gates checked')
