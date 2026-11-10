"""Keep fixed-schedule proofs separate from the native dependency-order diagnostic."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROFILE='fixed topological schedule; same-shape PRED pure local step; arbitrary external state/errors; final state retained on failure'
SCOPE='native verified HloSchedules; per-instruction HloEvaluator with cached substitutions; mock synchronous effects'
PROBES=('EFFECTFUL_MODEL original=(Except.error (EffectfulControls.Error.stopped), [7, 0, 0, 9])\n'
        'EFFECTFUL_MODEL redirected=(Except.error (EffectfulControls.Error.stopped), [7, 0, 0, 9])\n'
        'EFFECTFUL_MODEL success=(Except.ok false, [7, 0, 0])\n'
        'ORDER_MODEL original=["A", "B"]\nORDER_MODEL replacement=["B", "A"]\n')


def check_contract(root=ROOT):
    contract=json.loads((root/'census/effectful-graph-contract.json').read_text())
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['status']=='kernel_checked_fixed_schedule_effectful_context_not_source_acceptance'
    assert contract['accepted_source_rewrites']==0
    assert contract['all_schedule_refinement_proved'] is False
    assert contract['production_backend_executed'] is False
    assert contract['source_case']=='HandleAnd/rhs-zero'
    assert contract['native_evidence']=='reports/control-order-replay-v1/result.json'
    pin=json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['source_commit']==pin
    manifest=json.loads((root/'sources/control-effects-contract-manifest.json').read_text())
    assert manifest['source_commit']==pin and len(manifest['files'])==6
    for record in manifest['files']+contract['contracts']:
        path=root/record['path']
        if 'line' in record:
            body='\n'.join(path.read_text().splitlines()[record['line']-1:record['end_line']]).encode()
            assert hashlib.sha256(body).hexdigest()==record['source_body_sha256']
        else:
            assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    assert [c['id'] for c in contract['contracts']]==['and-forwarding','compatibility-helper',
        'visitor-replacement-defaults','computation-replacement','operand-removal',
        'copy-explicit-control','schedule-validation','evaluator-substitution']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    group=proofs['effectful_graph_context']
    for key in ('status','rules','accepted_source_rewrites','all_schedule_refinement_proved'):
        assert group[key]==contract[key]
    assert group['semantic_track']==PROFILE
    assert len(group['rules'])==12
    assert {r['source_case']:r['theorem'].replace('.EffectfulBooleanDag.','.BooleanDag.') for r in group['rules']}=={r['source_case']:r['theorem'] for r in proofs['graph_context']['rules']}
    for row in group['rules']:
        assert row['status']==contract['status']
        assert row['source_partition'].startswith('PRED same-shape pure local step in fixed effectful schedule only')
        if row['source_case']=='HandleXor/equal-inputs':
            assert 'pointer-identical self-input subcase only, not Identical equivalence' in row['source_partition']
    assert len(contract['support_theorems'])==7
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    order=proofs['control_order_diagnostic']
    assert order['certificates']==contract['order_certificates'] and len(order['certificates'])==7
    assert order['status']=='kernel_checked_finite_dependency_order_countermodel_not_cpp_extraction'
    assert order['accepted_source_rewrites']==0 and order['production_backend_executed'] is False
    assert order['source_case']==contract['source_case'] and order['native_evidence']==contract['native_evidence']


def check_archive(root=ROOT):
    folder=root/'reports/control-order-replay-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_control_order_relaxation_reproduced'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run']
    assert result['native_schedule_verified'] and result['custom_call_callbacks']
    assert result['execution_scope']==SCOPE and '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^CONTROL_ORDER_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) reachable_before=([01]) reachable_after=([01]) reverse_before=([01]) reverse_after=([01]) forward_trace=(A,B) reverse_trace=(B,A|invalid) actors_retained=1 verified=1$',log,re.M)
    expected=[]
    for name,identity,predecessor,successor in [('annihilator_successor',False,False,True),('annihilator_predecessor',False,True,True),('identity_successor',True,False,True),('annihilator_unordered',False,False,False)]:
        for mode in ('control','handler','pass'):
            changed=mode!='control' and not predecessor
            after=successor and not(changed and not identity)
            expected.append((name,mode,str(int(changed)),str(int(successor)),str(int(after)),str(int(not successor)),str(int(not after)),'A,B','invalid' if after else 'B,A'))
    assert rows==expected
    assert result['cases']==[dict(name=n,mode=m,changed=c=='1',reachable_before=b=='1',reachable_after=a=='1',reverse_before=rb=='1',reverse_after=ra=='1',forward_trace=f,reverse_trace=r,actors_retained=True,verified=True) for n,m,c,b,a,rb,ra,f,r in rows]
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['effectful_dag_controls']
    assert probe==dict(exit_code=0,stdout=PROBES,stderr='')
    negative=model['checks']['invalid_effectful_dag']
    assert negative['exit_code']!=0 and 'rfl' in negative['stdout']+negative['stderr']
    assert model['checked_effectful_graph_context_theorems']==12
    assert model['checked_control_order_certificates']==7
    assert model['accepted_source_rewrites']==0
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('12 fixed-schedule effectful context proofs; native successor-order loss reproduced with three controls; source acceptance remains zero')
