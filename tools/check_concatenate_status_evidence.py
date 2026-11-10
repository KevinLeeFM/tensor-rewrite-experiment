"""Validate native graph/status evidence without promoting it to value failure or Lean proof."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from concatenate_status_cases import expected_rows

ROOT=Path(__file__).resolve().parents[1]
PATTERN=r'^CONCAT_STATUS_RESULT case=(\w+) layout=([01]) profile=(plain|predecessor|successor) mode=(control|handler|pass|fixedpoint) step=([123]) changed=([01]) delta=(-?[0-9]+) root_retained=([01]) before=([-0-9a-z,]+) after=([-0-9a-z,]+) verified=1$'


def load(root,path):return json.loads((root/path).read_text())


def validate_contract(contract):
    assert contract['status']=='native_operational_evidence_not_value_counterexample_or_source_acceptance'
    assert contract['accepted_source_rewrites']==0 and not contract['source_correspondence_reviewed']
    assert not contract['lean_certified'] and not contract['backend_execution_claimed']
    assert not contract['tensor_value_counterexample_claimed']
    assert contract['semantic_denominator'] is None and contract['family_denominator'] is None
    assert (contract['native_run_count'],contract['false_changed_with_added_nodes_run_count'],contract['value_change_run_count'])==(120,15,0)
    assert contract['early_control_rejection']=='predecessors_only'
    assert contract['existing_instruction_api_relays_successors']
    assert contract['fixedpoint_false_changed_stops_after_one_traversal']
    assert not contract['nontermination_claimed'] and contract['additional_lean_lines']==0
    assert len(contract['source_cases'])==5
    assert contract['failed_run_archives']==['reports/concatenate-status-replay-v1','reports/concatenate-status-replay-v2']


def validate_native(result,log):
    assert result['status']=='concatenate_allocation_with_false_changed_observed'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['native_operator_evaluation']
    assert result['accepted_source_rewrites']==0 and not result['source_correspondence_reviewed']
    assert 'no compiled backend' in result['execution_scope']
    assert result['handler_initialization']=='public Run with Concatenate/Slice suppressed; unchanged status/graph required before original handler'
    rows=re.findall(PATTERN,log,re.M);assert rows==expected_rows() and len(rows)==120
    expected=[dict(name=n,layout_sensitive=l=='1',profile=p,mode=m,step=int(t),changed=c=='1',delta=int(d),root_retained=k=='1',before=b,after=a,verified=True) for n,l,p,m,t,c,d,k,b,a in rows]
    assert result['cases']==expected
    retained_mutations=[r for r in expected if not r['changed'] and r['delta']>0]
    assert len(retained_mutations)==15
    assert all(r['profile']=='predecessor' and r['root_retained'] for r in retained_mutations)
    assert all(r['before']==r['after'] for r in expected)
    assert any(r['mode']=='fixedpoint' and r['delta']==2 and not r['changed'] for r in retained_mutations)
    assert any(r['profile']=='successor' and r['mode']=='pass' and r['name']=='adjacent' and r['delta']==-3 for r in expected)


def check_archive(root=ROOT):
    contract=load(root,'census/concatenate-status-contract.json');validate_contract(contract)
    assert contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    for span in contract['contracts']:
        body='\n'.join((root/span['path']).read_text().splitlines()[span['line']-1:span['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==span['source_body_sha256']
    folder=Path('reports/concatenate-status-replay-v3');result=load(root,folder/'result.json')
    validate_native(result,(root/folder/'test.log').read_text())
    assert result['source_commit']==contract['source_commit']
    assert result['pass_source_sha256']==hashlib.sha256((root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()).hexdigest()
    assert len(result['files'])==6 and '--nocache_test_results' in result['command']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    for record in result['files']:
        path=Path(record['path']);assert path.parent==folder
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
    fixture=(root/folder/'fixture.cc').read_text()
    assert fixture==(root/'tests/xla/concatenate_status_replay_test.cc').read_text()
    for text in ('ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())',
                 'set_is_layout_sensitive(layout)','set_run_to_fixed_point(mode=="fixedpoint")',
                 'set_use_fast_path(false)','marker->control_predecessors()[0],computation->root_instruction()',
                 'original_root->control_predecessors()[0],marker'):
        assert text in fixture
    xml=ET.parse(root/folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    events=[json.loads(line) for line in (root/folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    for directory in contract['failed_run_archives']:
        failed=load(root,Path(directory)/'result.json')
        assert failed['status']=='replay_failed' and not failed['test_passed']
        assert failed['exit_code']!=0
        for record in failed['files']:
            assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256']


if __name__=='__main__':
    check_archive()
    print('Concatenate status evidence passed:120 native runs,15 false-changed allocations,0 value changes; no Lean/source acceptance.')
