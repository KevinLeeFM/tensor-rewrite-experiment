"""Check reachable constructor failure and preserve the unresolved empty-size domain boundary."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from dynamic_slice_empty_reshape_cases import expected_rows

ROOT=Path(__file__).resolve().parents[1]
PATTERN=r'^DS_EMPTY_RESHAPE_RESULT case=(\w+) mode=(control|handler|pass) original_verified=1 outcome=(valid|checked_fatal) changed=(0|1|unreturned)$'


def load(root,path):return json.loads((root/path).read_text())


def validate_contract(contract):
    assert contract['status']=='native_checked_fatal_on_verifier_accepted_empty_shape_semantic_domain_unresolved'
    assert contract['accepted_source_rewrites']==0 and not contract['source_correspondence_reviewed']
    assert not contract['lean_certified'] and not contract['backend_execution_claimed']
    assert not contract['native_operator_evaluation'] and not contract['semantic_domain_resolved']
    assert contract['published_xla_sizes_strictly_positive'] and contract['pinned_shape_inference_accepts_zero']
    assert contract['stablehlo_zero_sizes_permitted'] and not contract['stablehlo_contract_automatically_transferred_to_hlo']
    assert contract['semantic_denominator'] is None and contract['additional_lean_lines']==0
    assert contract['source_cases']==['HandleDynamicSlice/unit-reshape']
    assert (contract['native_run_count'],contract['checked_fatal_run_count'])==(21,4)
    assert contract['constructor_failure']==dict(original_operand_shape=[2],reshape_shape=[1,2],output_slice_sizes=[0,1],new_dynamic_slice_sizes=[1],new_reshape_element_counts=[1,0])
    assert 'BEFORE constant-index conversion' in contract['earlier_returns']
    assert len(contract['failed_run_archives'])==2


def validate_native(result,log):
    assert result['status']=='dynamic_slice_empty_inserted_axis_checked_fatal_observed'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run']
    assert not result['native_operator_evaluation'] and not result['semantic_domain_resolved']
    assert result['accepted_source_rewrites']==0 and not result['source_correspondence_reviewed']
    assert 'no operator evaluation or compiled backend' in result['execution_scope']
    assert result['handler_initialization']=='public Run with DynamicSlice/Reshape suppressed; unchanged status/graph required before original handler'
    rows=re.findall(PATTERN,log,re.M);assert rows==expected_rows() and len(rows)==21
    assert result['cases']==[dict(name=n,mode=m,original_verified=True,outcome=o,changed=None if c=='unreturned' else c=='1') for n,m,o,c in rows]
    assert sum(row[2]=='checked_fatal' for row in rows)==4
    assert all(row[1]!='control' for row in rows if row[2]=='checked_fatal')


def check_archive(root=ROOT):
    contract=load(root,'census/dynamic-slice-empty-reshape-contract.json');validate_contract(contract)
    assert contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    for span in contract['contracts']:
        body='\n'.join((root/span['path']).read_text().splitlines()[span['line']-1:span['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==span['source_body_sha256']
    case=next(c for c in load(root,'census/tensor-index-cases.json')['cases'] if c['id']=='HandleDynamicSlice/unit-reshape')
    assert not case['checks_inserted_axis_slice_size_one'] and case['proof'] is None
    assert 'no inserted-output-axis slice-size1 check' in ' '.join(case['dependencies'])
    folder=Path('reports/dynamic-slice-empty-reshape-replay-v4');result=load(root,folder/'result.json')
    validate_native(result,(root/folder/'test.log').read_text())
    assert result['source_commit']==contract['source_commit']
    assert result['pass_source_sha256']==hashlib.sha256((root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()).hexdigest()
    assert len(result['files'])==6 and '--nocache_test_results' in result['command']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    for record in result['files']:
        path=Path(record['path']);assert path.parent==folder
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
    fixture=(root/folder/'fixture.cc').read_text()
    assert fixture==(root/'tests/xla/dynamic_slice_empty_reshape_replay_test.cc').read_text()
    for text in ('ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())','ASSERT_DEATH',
                 'StaticExtentProduct','HandleReshape','root->operand(0)->opcode(),HloOpcode::kBitcast'):
        assert text in fixture
    xml=ET.parse(root/folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    events=[json.loads(line) for line in (root/folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    for directory in contract['failed_run_archives']:
        failed=load(root,Path(directory)/'result.json')
        assert failed['status']=='replay_failed' and not failed['test_passed'] and failed['exit_code']!=0
        for record in failed['files']:
            assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256']


if __name__=='__main__':
    check_archive()
    print('DynamicSlice empty-reshape evidence passed:21 native runs,4 checked deaths; intended semantic domain unresolved; no Lean/source acceptance.')
