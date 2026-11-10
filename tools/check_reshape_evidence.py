"""Check reshape's logical profile and distinguish handler from full-pass evidence."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROFILE='static bounded shapes; logical dim0-major order; mathematical element counts; physical layout separate'
SCOPE='separate direct handler, full pass and no-rewrite controls'
VALUES={'compose_default':(6,'0,1,2,3,4,5'),'compose_column':(6,'0,1,2,3,4,5'),
        'identity':(6,'0,1,2,3,4,5'),'scalar_chain':(1,'42'),'empty':(0,'empty')}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/reshape-contract.json').read_text())
    assert contract['status']=='kernel_checked_logical_reshape_not_full_source_acceptance'
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['accepted_source_rewrites']==0
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['source_cases']==['HandleReshape/'+case for case in ('identity','compose','empty')]
    assert [r['id'] for r in contract['contracts']]==['reshape-handler','reshape-evaluator','reshape-literal','reshape-shape','reshape-documentation']
    for record in contract['contracts']:
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert len(contract['support_theorems'])==8
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    for key in ('accepted_source_rewrites','profile','source_cases','native_scope','native_evidence'):
        assert proofs['reshape'][key]==contract[key]
    source_cases={c['id']:c for c in json.loads((root/'census/shape-cases.json').read_text())['cases']}
    assert [r['source_case'] for r in contract['rules']]==contract['source_cases']
    for rule in contract['rules']:
        assert rule in proofs['rules'] and not rule['source_rewrite_accepted']
        assert rule['semantic_track']=='static logical dim0-major indexing; arbitrary rank and element type'
        assert rule['status']=='pilot_value_proof_pending_source_graph_review'
        assert source_cases[rule['source_case']]['proof'] is None


def check_archive(root=ROOT):
    folder=root/'reports/reshape-replay-v3'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_reshape_values_preserved'
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['xla_operator_evaluator_run']
    assert result['test_passed'] and result['exit_code']==0 and '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for record in result['files']:
        path=root/record['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==record['sha256']
    rows=re.findall(r'^RESHAPE_RESULT case=(\w+) mode=(control|handler|pass) changed=([01]) elements=(\d+) values=([0-9,]+|empty) rewritten_verified=1$',(folder/'test.log').read_text(),re.M)
    expected=[(name,mode,str(int(mode!='control')),str(count),labels)
              for name,(count,labels) in VALUES.items() for mode in ('control','handler','pass')]
    assert rows==expected
    assert result['cases']==[dict(name=n,mode=m,changed=c=='1',elements=int(e),values=v,rewritten_verified=True)
                             for n,m,c,e,v in rows]
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['reshape_controls']
    assert probe['exit_code']==0 and not probe['stderr']
    assert probe['stdout']=='RESHAPE_MODEL values=0,1,2,3,4,5\nRESHAPE_MODEL composed=0,1,2,3,4,5\nRESHAPE_MODEL empty=0\n'
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('Logical reshape checked: 5 direct-handler, 5 full-pass and 5 no-rewrite controls; source acceptance remains zero')
