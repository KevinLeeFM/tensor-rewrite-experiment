"""Check source-promoted signed words while retaining scalar/graph trust boundaries."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from signed_word_cases import expected_rows,values,signed,NAMES,BASE_NAMES

ROOT=Path(__file__).resolve().parents[1]
PROFILE='modular words and injective signed observations; arbitrary shapes and widths with width <= promoted; no floating/custom subbyte or graph/API proof'
SCOPE='s8/s16/s32/s64 words and signed observations; typed 64-bit intermediate arithmetic; native HloEvaluator; no floating or whole-source graph claim'
SUPPORT=['narrow_ofInt','signed_promotion_exact','signed_cast_narrow','promoted_add','promoted_mul','promoted_sub','promoted_neg','tensor_signed_decode_injective']


def check_contract(root=ROOT):
    contract=json.loads((root/'census/signed-word-contract.json').read_text())
    assert contract['status']=='kernel_checked_promoted_signed_words_not_full_source_acceptance'
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['source_scope']=='typed evaluator s8/s16/s32/s64; exact input widening, unsigned binary arithmetic, signed reinterpretation and return narrowing; backend/ABI/source correspondence review pending'
    assert contract['accepted_source_rewrites']==0
    assert contract['source_correspondence_reviewed'] is False and contract['source_cpp_extraction_proved'] is False
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['native_evidence']=='reports/signed-word-replay-v2/result.json'
    assert contract['prior_native_evidence']=='reports/signed-word-replay-v1/result.json'
    assert (contract['native_run_count'],contract['model_vector_count'])==(144,48)
    assert contract['support_theorems']==['TensorRewrite.Pilot.PromotedWordArithmetic.'+n for n in SUPPORT]
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert proofs['signed_words']==contract
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    expected_related=sorted(r['theorem'] for r in proofs['rules'] if r['module'] in (
        'TensorRewrite/Pilot/ModularArithmetic.lean','TensorRewrite/Pilot/ModularArithmeticBridges.lean',
        'TensorRewrite/Pilot/Subtract.lean'))
    assert contract['related_word_value_theorems']==expected_related and len(expected_related)==33
    assert contract['native_recipe_source_cases']==dict(add_zero='HandleAdd/rhs-zero',add_constant='HandleAdd/constant-right',add_assoc='HandleAdd/constant-sum-direct-constants',factor='HandleAdd/factor-rhs-rhs',mul_zero='HandleMultiply/rhs-zero',mul_one='HandleMultiply/rhs-one',mul_neg_neg='HandleMultiply/negated-operands',four_factors='HandleMultiply/four-factors',sub_self='HandleSubtract/self',sub_zero='HandleSubtract/zero',sub_constant='HandleSubtract/constant',neg_neg='HandleNegate/involution')
    assert list(contract['native_recipe_source_cases'])==list(NAMES)
    cases={c['id']:c for name in ('simple-cases','arithmetic-cases')
           for c in json.loads((root/('census/'+name+'.json')).read_text())['cases']}
    assert all(cases[c]['proof'] is None for c in contract['native_recipe_source_cases'].values())
    assert contract['manifest']=='sources/signed-arithmetic-contract-manifest.json'
    manifest=json.loads((root/contract['manifest']).read_text())
    assert manifest['source_commit']==contract['source_commit'] and len(manifest['files'])==5
    for record in manifest['files']:
        assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256']
    assert contract['source_dtype_profiles']==[dict(dtype='s'+str(w),stored_width=w,
        elementwise_type='int64_t',binary_unsigned_type='uint64_t',binary_intermediate_width=64,
        negate_unsigned_width=w,instantiation='sources/xla/xla/hlo/evaluator/hlo_evaluator_typed_visitor_int'+str(w)+'.cc')
        for w in (8,16,32,64)]
    for profile in contract['source_dtype_profiles']:
        width=profile['stored_width']
        expected='template class HloEvaluatorTypedVisitor<int'+str(width)+'_t'+(', int64_t' if width<64 else '')+'>;'
        assert expected in (root/profile['instantiation']).read_text()
    assert [(r['id'],r['line'],r['end_line']) for r in contract['contracts']]==[
        ('signed-typed-dispatch',877,910),('unsigned-safe-arithmetic',87,109),
        ('signed-native-negate',381,404),('add-subtract-multiply',484,525),('typed-input-result-casts',1168,1224)]
    for record in contract['contracts']:
        expected_path='sources/xla/xla/hlo/evaluator/'+('hlo_evaluator.cc' if record['id']=='signed-typed-dispatch' else 'hlo_evaluator_typed_visitor.h')
        assert record['path']==expected_path
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']


def check_files(root,folder,result):
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']


def check_native(root,version,names):
    folder=root/('reports/signed-word-replay-v'+str(version))
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_signed_word_overflow_and_narrowing_preserved'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['native_operator_evaluation']
    assert result['execution_scope']==SCOPE and '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    check_files(root,folder,result)
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^SIGNED_WORD_RESULT dtype=(s8|s16|s32|s64) case=(\w+) mode=(control|handler|pass) changed=([01]) checked=(\d+) values=([0-9,]+) signed=([-0-9,]+) rewritten_verified=1$',log,re.M)
    expected=[r for r in expected_rows() if r[1] in names]
    assert rows==expected and len(rows)==len(names)*4*3
    assert result['cases']==[dict(dtype=d,name=n,mode=m,changed=c=='1',checked=int(k),values=list(map(int,v.split(','))),signed_values=list(map(int,s.split(','))),rewritten_verified=True) for d,n,m,c,k,v,s in rows]
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


def check_archive(root=ROOT):
    check_native(root,1,BASE_NAMES);check_native(root,2,NAMES)
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['signed_word_controls']
    expected=''.join('SIGNED_WORD_MODEL width='+str(w)+' case='+n+' values='+','.join(map(str,values(w,n)))+
        ' signed='+','.join(str(signed(w,v)) for v in values(w,n))+'\n' for w in (8,16,32,64) for n in NAMES)
    assert probe==dict(exit_code=0,stdout=expected,stderr='')
    invalid=model['checks']['invalid_signed_word']
    assert invalid['exit_code']!=0 and 'rfl' in invalid['stdout']+invalid['stderr']
    assert model['accepted_source_rewrites']==0


if __name__=='__main__':
    check_contract();check_archive()
    print('8 general signed promotion/observation bridges; 144 native runs and 48 Lean vectors agree; 64-bit intermediates pinned; source acceptance zero')
