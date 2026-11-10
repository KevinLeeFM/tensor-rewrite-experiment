"""Keep reducer-role and index-literal counterexamples separate from strengthened safe conditions."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from reducer_index_cases import expected_rows

ROOT=Path(__file__).resolve().parents[1]
PATTERN=r'^REDUCER_INDEX_RESULT family=(scatter|gather) case=(\w+) mode=(control|handler|pass) changed=([01]) before=([-0-9,]+) after=([-0-9,]+) rewritten_verified=1$'


def load(root,path):return json.loads((root/path).read_text())


def validate_profiles(scatter,gather):
    assert {c['id'] for c in scatter}=={'HandleAdd/scatter-concat','HandleAdd/scatter-nested','HandleAdd/scatter-single-rhs','HandleAdd/scatter-single-lhs'}
    for c in scatter:
        assert c['reducer_role_profiles']==['00','01','10','11']
        assert not c['matcher_checks_parameter_numbers'] and not c['matcher_checks_parameter_distinctness']
        assert 'NOT checked' in c['guard'] and c['proof'] is None
    assert gather['id']=='HandleGather/small-select-chain' and gather['proof'] is None
    assert not gather['checks_literal_representability']
    assert 'every position' in gather['literal_safe_condition']
    assert 'threshold129' in gather['literal_boundary_profile']


def check_contract(root=ROOT):
    arithmetic=load(root,'census/arithmetic-cases.json')['cases']
    tensor=load(root,'census/tensor-index-cases.json')['cases']
    validate_profiles([c for c in arithmetic if c['id'].startswith('HandleAdd/scatter-')],next(c for c in tensor if c['id']=='HandleGather/small-select-chain'))
    contract=load(root,'census/reducer-index-contract.json')
    assert contract['status']=='kernel_checked_role_and_literal_witnesses_source_correspondence_pending'
    assert contract['accepted_source_rewrites']==0 and not contract['source_correspondence_reviewed']
    assert not contract['backend_execution_claimed'] and not contract['preservation_claim_for_actual_source_guard']
    assert (contract['native_run_count'],contract['value_change_run_count'],contract['native_scatter_runs'],contract['native_gather_runs'],contract['model_vector_count'])==(75,14,48,27,13)
    assert len(contract['support_theorems'])==4 and len(contract['certificates'])==8
    assert contract['source_cases']==['HandleAdd/scatter-single-rhs','HandleAdd/scatter-single-lhs','HandleGather/small-select-chain']
    assert contract['related_unreplayed_scatter_cases']==['HandleAdd/scatter-concat','HandleAdd/scatter-nested']
    assert contract['gather_primary_witness_in_bounds']
    assert 'principal zero/maximum-index failures are in bounds' in contract['gather_out_of_bounds_controls']
    manifest=load(root,contract['normative_operation_manifest'])
    assert manifest['source_commit']==contract['source_commit']
    for record in manifest['files']:
        assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256']
    ledger=load(root,'census/pilot-value-proofs.json');assert ledger['reducer_index']==contract
    assert set(contract['support_theorems'])<=set(ledger['support_theorems'])
    assert contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    for span in contract['source_spans']:
        body='\n'.join((root/span['path']).read_text().splitlines()[span['line']-1:span['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==span['source_body_sha256']
    helpers=(root/'TensorRewrite/Pilot/ReducerIndexLemmas.lean').read_text()
    assert 'distinct : first ≠ second' in helpers and 'represented : ∀ position, position < extent' in helpers


def validate_native(result,log):
    assert result['status']=='scatter_reducer_roles_and_gather_narrowing_changes_observed'
    assert result['test_passed'] and result['exit_code']==0 and result['native_operator_evaluation']
    assert result['xla_full_pass_run'] and result['xla_handler_run']
    assert result['accepted_source_rewrites']==0 and not result['source_correspondence_reviewed']
    assert 'no compiled backend' in result['execution_scope']
    assert result['handler_initialization']=='public Run with Add/Gather suppressed; unchanged status/graph required before original handler'
    rows=re.findall(PATTERN,log,re.M);assert rows==expected_rows() and len(rows)==75
    assert result['cases']==[dict(family=f,name=n,mode=m,changed=c=='1',before=list(map(int,b.split(','))),after=list(map(int,a.split(','))),rewritten_verified=True) for f,n,m,c,b,a in rows]
    assert re.findall(r'^REDUCER_INDEX_CAST original=128 s8=(-?[0-9]+)$',log,re.M)==['-128']
    assert result['signed_narrowing_128_to_s8']==-128
    different=[r for r in result['cases'] if r['before']!=r['after']]
    assert len(different)==14 and sum(r['family']=='scatter' for r in different)==8
    assert sum(r['family']=='gather' for r in different)==6
    assert all(r['mode']!='control' for r in different)
    assert all(r['before']==r['after'] for r in result['cases'] if r['mode']=='control' or r['name'].endswith('layout1'))


def check_archive(root=ROOT):
    folder=Path('reports/reducer-index-replay-v1');result=load(root,folder/'result.json')
    log=(root/folder/'test.log').read_text();validate_native(result,log)
    assert result['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    assert result['pass_source_sha256']==hashlib.sha256((root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()).hexdigest()
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256']) and '--nocache_test_results' in result['command']
    assert len(result['files'])==6
    for record in result['files']:
        path=Path(record['path']);assert path.parent==folder
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
    fixture=(root/folder/'fixture.cc').read_text();assert fixture==(root/'tests/xla/reducer_index_replay_test.cc').read_text()
    for text in ('ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())',
                 'set_is_layout_sensitive(layout)','set_very_small_gather_size(test.threshold)',
                 'roles[0]', 'roles[1]', 'set_use_fast_path(false)', '.Convert(S8)'):
        assert text in fixture
    xml=ET.parse(root/folder/'test.xml')
    assert len(xml.findall('.//testcase'))==2 and not xml.findall('.//failure') and not xml.findall('.//error')
    events=[json.loads(s) for s in (root/folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    expected=[]
    for family,name,mode,changed,before,after in expected_rows():
        if mode!='pass':continue
        if family=='scatter':
            if not name.endswith('_rhs_layout0'):continue
            name=name.split('_')[0]
        expected.append('REDUCER_INDEX_MODEL family='+family+' case='+name+' before='+before+' after='+after+'\n')
    model=load(root,'reports/pilot-values.json')
    assert model['checks']['reducer_index_controls']==dict(exit_code=0,stdout=''.join(expected),stderr='')
    for name in ('invalid_reducer_role','invalid_gather_literal'):assert model['checks'][name]['exit_code']!=0
    contract=load(root,'census/reducer-index-contract.json')
    for theorem in contract['certificates']:
        expected_axioms={'propext'} if '.ScatterRoles.' in theorem else set()
        assert set(model['axiom_dependencies'][theorem])==expected_axioms
    assert all(set(model['axiom_dependencies'][t])=={'propext','Quot.sound'} for t in contract['support_theorems'])


if __name__=='__main__':
    check_contract();check_archive()
    print('Reducer/index evidence passed:75 native runs,13 model vectors,8 counterexample certificates,4 safe-condition lemmas.')
