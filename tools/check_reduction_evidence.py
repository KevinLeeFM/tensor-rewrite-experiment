"""Check static reduction evidence without treating nonidentity inputs as legal counterexamples."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROFILE='static single-output ordered fibers; exact initializer law explicit; reassociation and physical layout separate'
SCOPE='separate direct handler, full pass and no-rewrite controls'
VALUES={'unit_axes':('0,1,0','0,1,0',True,True),
        'no_axes':('1,0,1,0,1,0','1,0,1,0,1,0',True,True),
        'empty_reduced':('1,1,1,1,1,1','1,1,1,1,1,1',True,True),
        'empty_kept':('empty','empty',True,True),'scalar':('0','0',True,True),
        'nontrivial_axes':('0,0,1','0,0,1',False,True),
        'nonidentity_control':('0,0,0','0,1,0',True,False)}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/reduction-logical-contract.json').read_text())
    assert contract['status']=='kernel_checked_static_reduction_not_full_source_acceptance'
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['accepted_source_rewrites']==0
    assert contract['invalid_identity_case_is_source_counterexample'] is False
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    expected_cases=sorted(['BroadcastReduce/single','HandleReduce/empty-delegation',
                           'HandleReduce/same-element-count','ReplaceReduceWithReshape/single'])
    assert contract['source_cases']==expected_cases
    assert [c['id'] for c in contract['contracts']]==['reduce-handler','broadcast-helper','reshape-helper',
        'documented-laws','evaluator-initializer','evaluator-axes','shape-axis-validation']
    for record in contract['contracts']:
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert len(contract['support_theorems'])==9
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    for key in ('profile','accepted_source_rewrites','source_cases','native_scope','native_evidence',
                'invalid_identity_case_is_source_counterexample'):
        assert proofs['reduction'][key]==contract[key]
    source={c['id']:c for c in json.loads((root/'census/reduction-cases.json').read_text())['cases']}
    names=['reduceTensor_empty_input','reduceTensor_empty_output','reduceTensor_sameCount']
    assert [r['theorem'] for r in contract['rules']]==['TensorRewrite.Pilot.Reduction.'+n for n in names]
    for rule in contract['rules']:
        assert rule in proofs['rules'] and rule['source_rewrite_accepted'] is False
        assert rule['semantic_track']==PROFILE and rule['status']=='pilot_value_proof_pending_source_graph_review'
        for case in [rule['source_case']]+rule['additional_source_cases']:
            assert case in expected_cases and source[case]['proof'] is None
    assert contract['rules'][2]['source_partition']=='single output; equal counts; actual initializer left identity explicit'


def check_archive(root=ROOT):
    folder=root/'reports/reduction-replay-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_reduction_identity_profile_checked'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['xla_operator_evaluator_run']
    assert result['invalid_identity_case_is_source_counterexample'] is False
    assert '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    rows=re.findall(r'^REDUCTION_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) identity_law=([01]) before=([01,]+|empty) after=([01,]+|empty) rewritten_verified=1$',(folder/'test.log').read_text(),re.M)
    expected=[(n,m,str(int(changed and m!='control')),str(int(identity)),before,after if m!='control' else before)
              for n,(before,after,changed,identity) in VALUES.items() for m in ('control','handler','pass')]
    assert rows==expected
    assert result['cases']==[dict(name=n,mode=m,changed=c=='1',identity_law=i=='1',before=b,after=a,rewritten_verified=True)
                             for n,m,c,i,b,a in rows]
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['reduction_controls']
    assert probe['exit_code']==0 and not probe['stderr']
    expected_model=''.join('REDUCTION_MODEL case='+name+' values='+before+'\n'
                          for name,(before,_,_,identity) in VALUES.items() if identity)
    expected_model+='REDUCTION_MODEL case=nonidentity_control before=0,0,0 after=0,1,0\n'
    assert probe['stdout']==expected_model
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('Reduction profiles checked: 7 handler, 7 pass, 7 no-rewrite runs; invalid initializer remains a domain control')
