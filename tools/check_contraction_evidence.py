"""Keep logical contraction proofs, native controls and bit observations separately scoped."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from contraction_cases import PROFILES,expected_word_rows,expected_fp_rows,word_values

ROOT=Path(__file__).resolve().parents[1]
WORD_PATTERN=r'^CONTRACTION_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) checked=(\d+) values=([-0-9,]+|empty) rewritten_verified=1$'
FP_PATTERN=r'^CONTRACTION_FP_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) before=([0-9,]+) after=([0-9,]+) bits_equal=([01]) numeric_equal=1 rewritten_verified=1 rne=1$'


def load(root,path):
    return json.loads((root/path).read_text())


def validate_contract(contract):
    assert contract['status']=='kernel_checked_logical_contraction_not_full_source_acceptance'
    assert contract['accepted_source_rewrites']==0
    assert not contract['source_correspondence_reviewed'] and not contract['source_cpp_extraction_proved']
    assert not contract['fp_observation_contract_adopted'] and not contract['fp_diagnostic_is_source_refutation']
    assert 'ordered scalar accumulation' in contract['profile']
    assert 'not a full IEEE or backend contract' in contract['fp_profile']
    assert len(contract['value_theorems'])==6 and len(contract['support_theorems'])==6
    assert len(contract['diagnostic_certificates'])==4
    assert (contract['native_run_count'],contract['model_vector_count'])==(57,15)
    assert len(contract['source_obligations'])==5


def check_contract(root=ROOT):
    contract=load(root,'census/contraction-contract.json');validate_contract(contract)
    assert contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    proofs=load(root,'census/pilot-value-proofs.json');assert proofs['contraction']==contract
    assert set(contract['value_theorems'])<={r['theorem'] for r in proofs['rules']}
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    for record in contract['contracts']:
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']
    rules=(root/'TensorRewrite/Pilot/ContractionRules.lean').read_text()
    assert 'identityAfterFinish : ∀ value, finish (add zero value) = finish value' in rules
    assert 'terms_length plan multiply lhs rhs output' in rules


def validate_native(result,log,version):
    assert result['status']=='integer_dot_preserved_signed_zero_difference_observed'
    assert result['test_passed'] and result['exit_code']==0 and result['native_operator_evaluation']
    assert result['xla_full_pass_run'] and result['xla_handler_run']
    assert not result['fp_diagnostic_is_source_refutation']
    assert result['handler_initialization']=='public Run with only HandleDot suppressed on unchanged parameter/Dot graph; then original base handler'
    assert 'backend permissions pending' in result['execution_scope']
    word=re.findall(WORD_PATTERN,log,re.M);fp=re.findall(FP_PATTERN,log,re.M)
    expected=expected_word_rows()
    if version==1:expected=[r for r in expected if r[0]!='matrix_contract']
    assert word==expected and fp==expected_fp_rows()
    assert result['word_cases']==[dict(name=n,mode=m,changed=c=='1',checked=int(k),values=[] if v=='empty' else list(map(int,v.split(','))),rewritten_verified=True) for n,m,c,k,v in word]
    assert result['fp_cases']==[dict(name=n,mode=m,changed=c=='1',before=list(map(int,b.split(','))),after=list(map(int,a.split(','))),bits_equal=e=='1',numeric_equal=True,rewritten_verified=True,rne=True) for n,m,c,b,a,e in fp]
    assert sum(not r['bits_equal'] for r in result['fp_cases'])==2
    assert all(not r['changed'] for r in result['word_cases'] if r['name']=='matrix_contract')


def check_archive(root=ROOT):
    manifest=load(root,'sources/manifest.json')
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    for version in (1,2,3):
        folder=Path('reports/contraction-replay-v'+str(version))
        result=load(root,folder/'result.json');log=(root/folder/'test.log').read_text()
        validate_native(result,log,version)
        assert result['source_commit']==manifest['xla_commit']
        assert result['pass_source_sha256']==hashlib.sha256(source.read_bytes()).hexdigest()
        assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
        assert '--nocache_test_results' in result['command']
        assert len(result['files'])==6
        for record in result['files']:
            path=Path(record['path']);assert path.parent==folder
            assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
        xml=ET.parse(root/folder/'test.xml')
        assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure')
        assert not xml.findall('.//error')
        events=[json.loads(s) for s in (root/folder/'events.json').read_text().splitlines()]
        assert any(e.get('finished',{}).get('overallSuccess') for e in events)
        assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
        fixture=(root/folder/'fixture.cc').read_text()
        for required in ('set_use_fast_path(false)','FE_TONEAREST','set_xla_cpu_enable_fast_math(false)',
                         'set_xla_cpu_fast_math_honor_nans(true)','set_xla_cpu_fast_math_honor_infs(true)',
                         'InitializedDotVisitor','ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())'):
            assert required in fixture,required
        if version==3:
            assert '{"matrix_contract","s32[2,3]","s32[3,4]","s32[2,4]","1","0","","",true,false}' in fixture
            assert 'name != "matrix_contract"' in fixture
            assert fixture==(root/'tests/xla/contraction_replay_test.cc').read_text()
    model=load(root,'reports/pilot-values.json')
    expected=''.join('CONTRACTION_MODEL case='+p[0]+' values='+(','.join(map(str,word_values(p))) or 'empty')+'\n' for p in PROFILES if not p[0].startswith('f32_'))
    expected+='ZERO_MAC_MODEL original=0 replacement=2147483648\n'
    assert model['checks']['contraction_controls']==dict(exit_code=0,stdout=expected,stderr='')
    assert model['checks']['invalid_contraction']['exit_code']!=0
    assert len(re.findall(': error',model['checks']['invalid_contraction']['stdout']))==1
    contract=load(root,'census/contraction-contract.json')
    assert all(model['axiom_dependencies'][t]==[] for t in contract['diagnostic_certificates'])


if __name__=='__main__':
    check_contract();check_archive()
    print('Contraction evidence passed: general ordered laws, 57 native controls, scoped signed-zero diagnostic.')
