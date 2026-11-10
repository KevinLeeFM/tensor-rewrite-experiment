"""Check the newly split failed-Iota source path and finite-word witness evidence."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from scaled_nested_slice_cases import expected_rows

ROOT=Path(__file__).resolve().parents[1]
CASE='HandleDynamicSlice/nested-after-scaled-probe'
PATTERN=r'^SCALED_NESTED_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) before=([-0-9,]+) after=([-0-9,]+) rewritten_verified=1$'


def load(root,path):return json.loads((root/path).read_text())


def validate_partition(row,direct):
    assert row['id']==CASE and row['proof'] is None
    assert row['source_path_partition']=='failed_scaled_iota_probe_local_binding'
    assert row['lhs']=='DynamicSlice(Multiply(DynamicSlice(x,inner),Broadcast(scalar)),outer)'
    assert row['discarded_original_operation']=='Multiply with broadcast runtime scalar'
    assert 'all prior returning branches fall through' in row['guard']
    assert 'result extent1; result type S32/U32' in row['guard']
    assert [e['line'] for e in row['local_binding_evidence']]==[8330,8333,8385]
    assert direct['id']=='HandleDynamicSlice/nested' and direct['source_path_partition']=='direct_original_data_operand'
    assert direct['lhs']=='DynamicSlice(DynamicSlice(x,inner),outer)'
    assert row['replacement_site_id']==direct['replacement_site_id']
    assert row['additional_replacement_sites']==direct['additional_replacement_sites']


def check_contract(root=ROOT):
    batch=load(root,'census/tensor-index-cases.json')
    row=next(c for c in batch['cases'] if c['id']==CASE)
    direct=next(c for c in batch['cases'] if c['id']=='HandleDynamicSlice/nested')
    validate_partition(row,direct)
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    lines=source.read_text().splitlines()
    for evidence in row['local_binding_evidence']:assert evidence['anchor'] in lines[evidence['line']-1]
    contract=load(root,'census/scaled-nested-slice-contract.json')
    assert contract['accepted_source_rewrites']==0 and not contract['preservation_claim']
    assert not contract['source_correspondence_reviewed'] and not contract['backend_execution_claimed']
    assert contract['status']=='finite_word_counterexample_certified_source_correspondence_pending'
    assert contract['source_case']==CASE and (contract['native_run_count'],contract['value_change_run_count'])==(33,8)
    assert len(contract['certificates'])==7
    assert contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    assert load(root,'census/pilot-value-proofs.json')['scaled_nested_slice']==contract
    for span in contract['source_spans']:
        body='\n'.join((root/span['path']).read_text().splitlines()[span['line']-1:span['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==span['source_body_sha256']
    revision=load(root,'census/schema-revisions.json')
    assert revision['semantic_denominator'] is None and revision['family_denominator'] is None
    r=revision['revisions'][-1]
    assert (r['previous_provisional_schema_count'],r['current_provisional_schema_count'],r['replacement_sites_added'])==(487,488,0)
    assert r['added_source_cases']==[CASE] and r['historical_frozen_packets_unchanged']
    assert len(load(root,'census/site-case-map.json')['bindings'])==488


def validate_native(result,log):
    assert result['status']=='stripped_multiply_nested_slice_value_changes' and result['test_passed']
    assert result['exit_code']==0 and result['xla_full_pass_run'] and result['xla_handler_run']
    assert result['native_operator_evaluation'] and result['accepted_source_rewrites']==0
    assert not result['source_correspondence_reviewed'] and 'no backend adoption' in result['execution_scope']
    assert result['handler_initialization']=='public Run with DynamicSlice suppressed; unchanged status/graph required before original handler'
    rows=re.findall(PATTERN,log,re.M);assert rows==expected_rows() and len(rows)==33
    assert result['cases']==[dict(name=n,mode=m,changed=c=='1',before=list(map(int,b.split(','))),after=list(map(int,a.split(','))),rewritten_verified=True) for n,m,c,b,a in rows]
    changed=[r for r in result['cases'] if r['before']!=r['after']];assert len(changed)==8
    assert all(r['name'] in ('scaled','negative_multiplier','zero_multiplier','constant_starts_disabled') and r['mode']!='control' for r in changed)
    assert all(r['before']==r['after'] for r in result['cases'] if r['mode']=='control')


def check_archive(root=ROOT):
    folder=Path('reports/scaled-nested-slice-replay-v1')
    result=load(root,folder/'result.json');log=(root/folder/'test.log').read_text();validate_native(result,log)
    assert result['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    assert result['pass_source_sha256']==hashlib.sha256((root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()).hexdigest()
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256']) and '--nocache_test_results' in result['command']
    assert len(result['files'])==6
    for record in result['files']:
        path=Path(record['path']);assert path.parent==folder
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
    fixture=(root/folder/'fixture.cc').read_text();assert fixture==(root/'tests/xla/scaled_nested_slice_replay_test.cc').read_text()
    for text in ('ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())',
                 'set_disable_dynamic_slice_to_slice_conversion','root->operand(0)->parameter_number(),0',
                 'set_use_fast_path(false)','set_run_to_fixed_point(false)'):
        assert text in fixture
    xml=ET.parse(root/folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    events=[json.loads(s) for s in (root/folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    model=load(root,'reports/pilot-values.json')
    expected=''.join('SCALED_NESTED_MODEL case='+n+' before='+str(b)+' after=4\n' for n,b in [('scaled',28),('negative_multiplier',-12),('one_multiplier',4),('zero_multiplier',0)])
    assert model['checks']['scaled_nested_controls']==dict(exit_code=0,stdout=expected,stderr='')
    assert model['checks']['invalid_scaled_nested']['exit_code']!=0
    contract=load(root,'census/scaled-nested-slice-contract.json')
    assert all(set(model['axiom_dependencies'][t])=={'propext','Classical.choice','Quot.sound'} for t in contract['certificates'])


if __name__=='__main__':
    check_contract();check_archive()
    print('Scaled nested-DynamicSlice evidence passed: distinct source partition;33 native runs;7 word/index certificates.')
