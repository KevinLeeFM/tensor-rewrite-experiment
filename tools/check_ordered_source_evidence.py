"""Validate scoped source-path records and the NaN-aware Compare diagnostic."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from compare_nonnegative_cases import expected_rows

ROOT=Path(__file__).resolve().parents[1]
PATTERN=r'^NONNEG_COMPARE_RESULT kind=(\w+) direction=(GE|LE|LT|GT) mode=(control|handler|pass) changed=([01]) before=([01,]+) after=([01,]+) rewritten_verified=1 cpu_fast_math=0 honor_nans=1 honor_infs=1 evaluator_fast_path=0 simplifier_fast_math=0$'


def load(root,path):
    return json.loads((root/path).read_text())


def check_span(root,span):
    body='\n'.join((root/span['path']).read_text().splitlines()[span['line']-1:span['end_line']])
    assert hashlib.sha256(body.encode()).hexdigest()==span['source_body_sha256']


def validate_paths(record,cases):
    assert record['status']=='source_inspected_ordered_paths_not_accepted_semantic_census'
    assert record['accepted_source_rewrites']==0 and record['semantic_denominator'] is None
    assert record['family_denominator'] is None and not record['independent_review_complete']
    assert {f['name'] for f in record['source_functions']}=={'HandleBroadcast','HandleCompare','HandlePad'}
    assert len(record['case_links'])==len(cases)==41
    assert {c['schema_id'] for c in record['case_links']}==set(cases)
    for function in record['source_functions']:
        assert not function['independent_semantic_review'] and not function['semantic_closure_complete']
        expected={c for c,row in cases.items() if row['handler']==function['name']}
        actual=[c for s in function['stages'] for c in s['source_cases']]
        assert len(actual)==len(set(actual)) and set(actual)==expected
        assert set(function['source_cases'])==expected
        assert all(s['outcome_contract'] for s in function['stages'])
    stages={f['name']:{s['id']:s for s in f['stages']} for f in record['source_functions']}
    assert 'BEFORE replacement attempt' in ' '.join(stages['HandleBroadcast']['inserted-unit-axes']['effects_before_terminal'])
    assert 'no qualifying live user: return OK' in ' '.join(stages['HandleBroadcast']['scalar-operand']['outcome_contract'])
    assert 'CONTINUE' in ' '.join(stages['HandlePad']['compatible']['outcome_contract'])
    assert 'ONLY edge padding' in ' '.join(stages['HandlePad']['classify-padding']['effects_before_terminal'])
    assert 'NaN-producing' in ' '.join(stages['HandleCompare']['nonnegative-zero']['outcome_contract'])
    assert 'no node replacement' in ' '.join(stages['HandleCompare']['extremum-gt']['effects_before_terminal'])
    assert len(record['helpers'])==4 and all(not h['semantic_closure_complete'] for h in record['helpers'])


def check_paths(root=ROOT):
    cases={}
    for path in (root/'census').glob('*cases.json'):
        cases.update({c['id']:c for c in json.loads(path.read_text()).get('cases',[])
                      if c.get('handler') in ('HandleBroadcast','HandleCompare','HandlePad')})
    record=load(root,'census/ordered-source-paths.json');validate_paths(record,cases)
    assert record['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    for row in record['source_functions']+record['helpers']:check_span(root,row['source'])
    return record,cases


def validate_compare(result,log):
    assert result['status']=='nonnegative_guard_nan_truth_change_observed'
    assert result['test_passed'] and result['exit_code']==0
    assert result['native_operator_evaluation'] and result['xla_full_pass_run'] and result['xla_handler_run']
    assert result['accepted_source_rewrites']==0 and not result['source_correspondence_reviewed']
    assert 'no backend adoption' in result['execution_scope']
    assert result['handler_initialization']=='public Run with Compare suppressed; unchanged status/graph required before original handler'
    rows=re.findall(PATTERN,log,re.M);assert rows==expected_rows() and len(rows)==60
    assert result['cases']==[dict(kind=k,direction=d,mode=m,changed=c=='1',before=list(map(int,b.split(','))),after=list(map(int,a.split(','))),rewritten_verified=True) for k,d,m,c,b,a in rows]
    different=[r for r in result['cases'] if r['before']!=r['after']]
    assert len(different)==16
    assert all(r['direction'] in ('GE','LE') and r['mode']!='control' and r['kind']!='parameter' and r['before'][0]==0 and r['after'][0]==1 and r['before'][1:]==r['after'][1:] for r in different)


def check_compare(root=ROOT):
    contract=load(root,'census/ordered-compare-contract.json')
    assert contract['status']=='kernel_checked_necessary_ordered_nan_profile_not_source_acceptance'
    assert contract['accepted_source_rewrites']==0 and not contract['source_correspondence_reviewed']
    assert not contract['backend_observation_contract_adopted']
    assert 'no full arithmetic, producer or backend model' in contract['profile']
    assert (contract['native_run_count'],contract['boolean_change_run_count'])==(60,16)
    ledger=load(root,'census/pilot-value-proofs.json');assert ledger['ordered_compare']==contract
    assert len(contract['certificates'])==6
    for span in contract['contracts']:check_span(root,span)
    folder=Path('reports/compare-nonnegative-replay-v1');result=load(root,folder/'result.json')
    log=(root/folder/'test.log').read_text();validate_compare(result,log)
    assert result['source_commit']==contract['source_commit']==load(root,'sources/manifest.json')['xla_commit']
    assert result['pass_source_sha256']==hashlib.sha256((root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()).hexdigest()
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    assert '--nocache_test_results' in result['command'] and len(result['files'])==6
    for record in result['files']:
        path=Path(record['path']);assert path.parent==folder
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==record['sha256']
    fixture=(root/folder/'fixture.cc').read_text()
    assert fixture==(root/'tests/xla/compare_nonnegative_replay_test.cc').read_text()
    for text in ('ASSERT_FALSE(visitor.Initialize','ASSERT_EQ(original,module->ToString())',
                 'set_enable_fast_math(false)','set_use_fast_path(false)',
                 'set_xla_cpu_enable_fast_math(false)','set_xla_cpu_fast_math_honor_nans(true)',
                 'set_xla_cpu_fast_math_honor_infs(true)'):
        assert text in fixture
    xml=ET.parse(root/folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')
    events=[json.loads(s) for s in (root/folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    model=load(root,'reports/pilot-values.json')
    assert model['checks']['ordered_compare_controls']==dict(exit_code=0,stdout='ORDERED_COMPARE_MODEL left_nan_true_allowed=false right_nan_true_allowed=false false_allowed=true\n',stderr='')
    assert model['checks']['invalid_ordered_compare']['exit_code']!=0
    assert all(model['axiom_dependencies'][t]==[] for t in contract['certificates'])


def check_review_findings(root=ROOT):
    record=load(root,'census/source-review-findings.json')
    assert record['accepted_source_rewrites']==0 and record['semantic_denominator'] is None
    cases={c['id'] for p in (root/'census').glob('*cases.json')
           for c in json.loads(p.read_text()).get('cases',[])}
    assert {'nonnegative-nan-ordered-true-fold','scatter-reducer-parameter-roles',
            'gather-index-literal-representability','concatenate-post-allocation-compatibility-skip'}<={f['id'] for f in record['findings']}
    for finding in record['findings']:
        assert not finding['source_accepted'] and set(finding['source_cases'])<=cases
        if 'review' in finding:
            assert hashlib.sha256((root/finding['review']).read_bytes()).hexdigest()==finding['review_sha256']
            if finding['status']=='native_counterexample_certified_source_contract_review_pending':
                assert finding['native_replayed'] and finding['lean_certified']
                assert load(root,finding['native_evidence'])['test_passed']
                assert load(root,finding['lean_contract'])['accepted_source_rewrites']==0
            elif finding['status']=='native_operational_confirmation_not_value_failure_or_lean_proof':
                assert finding['native_replayed'] and not finding['lean_certified']
                assert load(root,finding['native_evidence'])['test_passed']
                contract=load(root,finding['operational_contract'])
                assert contract['accepted_source_rewrites']==0
                assert not contract['tensor_value_counterexample_claimed']
            elif finding['status']=='native_checked_fatal_semantic_domain_unresolved_not_lean_proof':
                assert finding['native_replayed'] and not finding['lean_certified']
                assert load(root,finding['native_evidence'])['test_passed']
                contract=load(root,finding['diagnostic_contract'])
                assert contract['accepted_source_rewrites']==0
                assert not contract['semantic_domain_resolved']
            else:
                assert not finding['native_replayed'] and not finding['lean_certified']
    ledger=load(root,'census/review-ledger.json')
    # The central ledger retains the original pending acceptance fields.
    assert ledger['accepted_source_rewrites']==0 and not ledger['denominator_frozen']
    rows=ledger['candidate_calls']
    linked={identity for r in rows for identity in r.get('related_independent_review_findings',[])}
    assert {f['id'] for f in record['findings']}<=linked


if __name__=='__main__':
    check_paths();check_compare();check_review_findings()
    print('Ordered-source evidence passed: 41 provisional schema links; 60 strict Compare runs; no source acceptance.')
