"""Check whole-schema static API paths and the bounded default-relay outcome replay."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET
from replacement_api_paths import load_inputs,validate

ROOT=Path(__file__).resolve().parents[1]
SCOPE='Bazel opt build; verified modules and HloEvaluator; bounded three single passes or one capped fixedpoint run'


def check_contract(root=ROOT):
    result=json.loads((root/'census/replacement-api-paths.json').read_text())
    validate(result,*load_inputs(root),root=root)
    assert len(result['source_cases'])==len(json.loads((root/'census/site-case-map.json').read_text())['bindings']) and len(result['api_endpoints'])==285
    assert all(r['reachable_endpoint_ids'] and not r['unresolved_entry_call_ids'] for r in result['source_cases'])
    diagnostic=result['native_status_diagnostic']
    assert diagnostic==dict(source_case='HandleAdd/constant-right',evidence='reports/replacement-status-replay-v1/result.json',scope=SCOPE,is_lean_refutation=False,unbounded_nontermination_claim=False,accepted_source_proof=None)
    source_cases=json.loads((root/'census/arithmetic-cases.json').read_text())['cases']
    assert next(c for c in source_cases if c['id']==diagnostic['source_case'])['proof'] is None
    used={i for case in result['source_cases'] for i in case['reachable_endpoint_ids']}
    assert used=={e['source_call_id'] for e in result['api_endpoints']}


def check_archive(root=ROOT):
    folder=root/'reports/replacement-status-replay-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_default_relay_skip_node_growth_reproduced'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run'] and result['native_operator_evaluation']
    assert result['execution_scope']==SCOPE and '--nocache_test_results' in result['command']
    assert '--compilation_mode=opt' in result['command']
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
    rows=re.findall(r'^REPLACEMENT_STATUS_RESULT profile=(\w+) mode=(control|handler|pass|fixedpoint) step=(\d+) changed=([01]) delta=(\d+) cumulative=(\d+) root_retained=([01]) selected=(\d+) verified=1 cap=(\d+)$',log,re.M)
    expected=[]
    for profile in ('plain','predecessor','successor'):
        for mode in ('control','handler','pass','fixedpoint'):
            cumulative=0
            for step in range(1,2 if mode=='fixedpoint' else 4):
                controlled=profile!='plain'
                changed=mode!='control' and (controlled or step==1)
                delta=0 if mode=='control' or not controlled else 50 if mode=='fixedpoint' else 1
                cumulative+=delta
                retained=mode=='control' or controlled or step!=1
                expected.append((profile,mode,str(step),str(int(changed)),str(delta),str(cumulative),str(int(retained)),'7','50'))
    assert rows==expected and len(rows)==30
    assert result['cases']==[dict(profile=p,mode=m,step=int(s),changed=c=='1',delta=int(d),cumulative=int(k),root_retained=r=='1',selected=int(v),verified=True,cap=int(cap)) for p,m,s,c,d,k,r,v,cap in rows]
    assert log.count('Algebraic simplifier is likely stuck in a circular simplification loop and ran for 50 runs')==2
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('Provisional schemas linked to typed API sites/boundaries; bounded 30-row default-relay outcome replay checked; source acceptance zero')
