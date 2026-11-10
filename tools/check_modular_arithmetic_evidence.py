"""Check general modular-value proofs and bounded native overflow agreement."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from modular_arithmetic_cases import expected_rows,values,NAMES

ROOT=Path(__file__).resolve().parents[1]
PROFILE='same-shape tensor words modulo 2^width; arbitrary finite rank/extents/width; no floating-point or full mutable-IR semantics'
SCOPE='static same-shape u8/u32/u64 arrays; native HloEvaluator; overflow values; no floating or whole-source graph claim'
PARTITION='modular integral value subcase; exact displayed operand order; source constants represented by same-shape tensors; AnyOrder alternatives, broadcast construction, helper guards and graph/API behavior pending'
PAIRS=[('add_rhs_zero','HandleAdd/rhs-zero'),('add_lhs_zero','HandleAdd/lhs-zero'),('add_comm','HandleAdd/constant-right'),('add_assoc','HandleAdd/constant-sum-direct-constants'),('sub_add_constant','HandleAdd/constant-subtract-direct-constants'),('add_sub_cancel_right','HandleAdd/cancel-subtract-rhs'),('add_sub_cancel_left','HandleAdd/cancel-subtract-lhs'),('mul_rhs_zero','HandleMultiply/rhs-zero'),('mul_lhs_zero','HandleMultiply/lhs-zero'),('mul_rhs_one','HandleMultiply/rhs-one'),('mul_lhs_one','HandleMultiply/lhs-one'),('mul_neg_neg','HandleMultiply/negated-operands'),('mul_assoc','HandleMultiply/constant-product'),('factor_right','HandleAdd/factor-rhs-rhs'),('factor_left','HandleAdd/factor-lhs-lhs'),('four_factors','HandleMultiply/four-factors')]


def check_contract(root=ROOT):
    contract=json.loads((root/'census/modular-arithmetic-contract.json').read_text())
    assert contract['status']=='kernel_checked_modular_values_not_full_source_acceptance'
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['accepted_source_rewrites']==0 and contract['source_correspondence_reviewed'] is False
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['native_evidence']=='reports/modular-arithmetic-replay-v1/result.json'
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert proofs['modular_arithmetic']==contract
    assert [(r['theorem'].rsplit('.',1)[1],r['source_case']) for r in contract['rules']]==PAIRS
    all_cases={c['id']:c for name in ('simple-cases','arithmetic-cases')
               for c in json.loads((root/('census/'+name+'.json')).read_text())['cases']}
    for rule in contract['rules']:
        assert rule in proofs['rules'] and rule['source_rewrite_accepted'] is False
        assert rule['status']=='pilot_value_proof_pending_source_graph_review'
        assert rule['semantic_track']==PROFILE and rule['source_partition']==PARTITION
        assert rule['theorem'].startswith('TensorRewrite.Pilot.ModularArithmetic.')
        assert rule['module']=='TensorRewrite/Pilot/ModularArithmetic.lean'
        assert all_cases[rule['source_case']]['proof'] is None
    assert [(r['id'],r['line'],r['end_line']) for r in contract['contracts']]==[
        ('add-identity-canonicalization',926,948),('add-reassociation',950,1012),
        ('add-factor',1054,1092),('multiply-identities-negation',5183,5225),
        ('multiply-reassociation',5255,5363)]
    for record in contract['contracts']:
        assert record['path']=='sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']


def check_archive(root=ROOT):
    folder=root/'reports/modular-arithmetic-replay-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_unsigned_modular_arithmetic_preserved'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['native_operator_evaluation']
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
    rows=re.findall(r'^MODULAR_RESULT dtype=(u8|u32|u64) case=(\w+) mode=(control|handler|pass) changed=([01]) checked=(\d+) values=([0-9,]+) rewritten_verified=1$',log,re.M)
    assert rows==expected_rows() and len(rows)==72
    assert result['cases']==[dict(dtype=d,name=n,mode=m,changed=c=='1',checked=int(k),values=list(map(int,v.split(','))),rewritten_verified=True) for d,n,m,c,k,v in rows]
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['modular_arithmetic_controls']
    expected=''.join('MODULAR_MODEL width='+str(width)+' case='+name+' values='+','.join(map(str,values(width,name)))+'\n' for width in (8,32,64) for name in NAMES)
    assert probe==dict(exit_code=0,stdout=expected,stderr='')
    invalid=model['checks']['invalid_modular_arithmetic']
    assert invalid['exit_code']!=0 and 'rfl' in invalid['stdout']+invalid['stderr']
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('16 general modular tensor laws; 72 native unsigned overflow runs agree with Lean/Python; full source acceptance remains zero')
