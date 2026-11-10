"""Check modular orientation/broadcast bridges without promoting matcher or graph claims."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from modular_bridge_cases import expected_rows,recipes,values

ROOT=Path(__file__).resolve().parents[1]
PROFILE='arbitrary finite shapes and widths; modular words; captured operand orientations and checked Broadcast axes; no floating or mutable-IR contract'
PARTITION='modular integral values; all stated captured operand orientations; concrete shared Broadcast map where present; matcher/literal evaluation, typing and graph/API effects pending'
SCOPE='u8/u32/u64 captured operand orders and static Broadcast axes; native HloEvaluator; guard controls; no floating or whole-source graph claim'
PAIRS=[('factor_any_order','HandleAdd/factor-rhs-rhs'),('mul_assoc_any_order','HandleMultiply/constant-product'),('four_factors_any_order','HandleMultiply/four-factors'),('add_broadcast_assoc','HandleAdd/constant-sum-broadcast-scalars'),('sub_add_broadcast','HandleAdd/constant-subtract-broadcast-scalars'),('mul_broadcast_assoc','HandleMultiply/legacy-constant-product-broadcast-scalars'),('broadcast_factor_any_order','HandleMultiply/broadcast-factor')]


def check_contract(root=ROOT):
    contract=json.loads((root/'census/modular-bridge-contract.json').read_text())
    assert contract['status']=='kernel_checked_operand_orientation_and_broadcast_values_not_full_source_acceptance'
    assert contract['profile']==PROFILE and contract['source_partition']==PARTITION and contract['native_scope']==SCOPE
    assert contract['accepted_source_rewrites']==0
    assert contract['source_matcher_extraction_proved'] is False and contract['graph_API_correspondence_proved'] is False
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['native_evidence']=='reports/modular-bridge-replay-v2/result.json'
    assert contract['failed_archive']=='reports/modular-bridge-replay-v1/result.json'
    assert contract['broadcast_contract']=='census/concrete-index-contract.json'
    assert (contract['native_recipe_count'],contract['native_run_count'],contract['model_row_count'])==(29,261,87)
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert proofs['modular_bridges']==contract
    assert [(r['theorem'].rsplit('.',1)[1],r['source_case']) for r in contract['rules']]==PAIRS
    cases={c['id']:c for name in ('simple-cases','arithmetic-cases')
           for c in json.loads((root/('census/'+name+'.json')).read_text())['cases']}
    for row in contract['rules']:
        assert row in proofs['rules'] and row['source_rewrite_accepted'] is False
        assert row['semantic_track']==PROFILE and row['source_partition']==PARTITION
        assert row['status']=='pilot_value_proof_pending_source_graph_review'
        assert row['module']=='TensorRewrite/Pilot/ModularArithmeticBridges.lean'
        assert row['theorem'].startswith('TensorRewrite.Pilot.ModularArithmetic.')
        assert cases[row['source_case']]['proof'] is None
    assert contract['rules'][0]['additional_source_cases']==[
        'HandleAdd/factor-lhs-lhs','HandleAdd/factor-lhs-rhs','HandleAdd/factor-rhs-lhs']
    assert all(cases[i]['proof'] is None for i in contract['rules'][0]['additional_source_cases'])
    assert contract['support_theorems']==['TensorRewrite.Pilot.OperandOrder.map₂_eq',
        'TensorRewrite.Pilot.Tensor.reindex_map₂','TensorRewrite.Pilot.Tensor.reindex_constant']
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    assert [(r['id'],r['line'],r['end_line']) for r in contract['contracts']]==[
        ('add-broadcast-gather',950,1000),('factor-any-order',1080,1093),
        ('multiply-four-any-order',5254,5284),('multiply-product-any-order',5285,5310),
        ('broadcast-scalar-movement',5311,5344),('legacy-broadcast-product',5345,5373)]
    for record in contract['contracts']:
        assert record['path']=='sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']


def check_files(root,folder,result):
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']


def check_archive(root=ROOT):
    folder=root/'reports/modular-bridge-replay-v2'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_modular_operand_order_and_broadcast_preserved'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['native_operator_evaluation']
    assert result['execution_scope']==SCOPE and '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    check_files(root,folder,result)
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^MODULAR_BRIDGE_RESULT dtype=(u8|u32|u64) case=(\w+) mode=(control|handler|pass) changed=([01]) checked=(\d+) values=([0-9,]+) rewritten_verified=1$',log,re.M)
    assert rows==expected_rows() and len(rows)==261
    assert result['cases']==[dict(dtype=d,name=n,mode=m,changed=c=='1',checked=int(k),values=list(map(int,v.split(','))),rewritten_verified=True) for d,n,m,c,k,v in rows]
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    failed_folder=root/'reports/modular-bridge-replay-v1'
    failed=json.loads((failed_folder/'result.json').read_text())
    assert failed['status']=='replay_failed' and failed['exit_code']==3 and failed['test_passed'] is False
    check_files(root,failed_folder,failed)
    assert 's1 = u8[] constant(2)' in (failed_folder/'test.log').read_text()
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['modular_bridge_controls']
    expected=''.join('MODULAR_BRIDGE_MODEL width='+str(w)+' case='+n+' values='+','.join(map(str,values(w,f,a)))+'\n' for w in (8,32,64) for n,f,*_,a in recipes())
    assert probe==dict(exit_code=0,stdout=expected,stderr='')
    invalid=model['checks']['invalid_modular_bridge']
    assert invalid['exit_code']!=0 and 'rfl' in invalid['stdout']+invalid['stderr']
    assert model['accepted_source_rewrites']==0


if __name__=='__main__':
    check_contract();check_archive()
    print('7 general orientation/broadcast bridges; all 261 native runs and 87 Lean vectors agree; guard/axis controls retained; source acceptance zero')
