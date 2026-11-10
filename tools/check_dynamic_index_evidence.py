"""Check DynamicSlice word profiles without erasing the observed oracle disagreement."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROFILE='bounded static extents; signedness-preserving finite-word decoding; evaluator u64 conversion separate'
EXPECTED_MODEL={'s32':[0,0,0,1,3,3,3],'s64':[0,0,0,1,3],'u32':[0,1,3],
                'u64_logical':[0,1,3,3,3],'u64_evaluator':[0,1,3,0,0]}
NAMES={'s32':['negative99','negative1','zero','one','three','four','large99'],
       's64':['minimum','negative1','zero','one','maximum'],
       'u32':['zero','one','maximum'],'u64':['zero','one','max_signed','high_bit','maximum']}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/dynamic-index-contract.json').read_text())
    assert contract['profile']==PROFILE and contract['accepted_source_rewrites']==0
    assert contract['diagnostic_scope']=='evaluator/logical index profiles; not an algebraic-simplifier counterexample'
    assert contract['native_scope']=='operator_evaluator_only_no_handler_or_pass'
    assert contract['disagreement_cases']==['u64/high_bit','u64/maximum']
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    manifest=json.loads((root/'sources/dynamic-index-contract-manifest.json').read_text())
    assert manifest['source_commit']==contract['source_commit']
    for f in manifest['files']:
        assert hashlib.sha256((root/f['path']).read_bytes()).hexdigest()==f['sha256']
    for c in contract['source_contracts']:
        body='\n'.join((root/c['path']).read_text().splitlines()[c['line']-1:c['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==c['source_body_sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    diagnostic=proofs['index_oracle_diagnostic']
    assert diagnostic['diagnostic_certificates']==contract['diagnostic_certificates']
    assert diagnostic['accepted_source_rewrites']==0 and diagnostic['scope']==contract['diagnostic_scope']


def check_archive(root=ROOT):
    folder=root/'reports/dynamic-index-evaluator-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='dynamic_index_profiles_observed_with_u64_disagreement'
    assert result['test_passed'] and result['exit_code']==0 and result['xla_operator_evaluator_run']
    assert result['xla_handler_run'] is False and result['xla_full_pass_run'] is False
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    files=result['files']
    assert len(files)==6 and {Path(f['path']).name for f in files}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for f in files:
        p=root/f['path'];assert p.parent==folder
        assert hashlib.sha256(p.read_bytes()).hexdigest()==f['sha256']
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^DYNAMIC_INDEX_RESULT type=(s32|s64|u32|u64) case=(\w+) native=(\d+) mathematical=(\d+) agree=([01])$',log,re.M)
    assert len(rows)==20
    parsed=[dict(type=t,name=n,native=int(v),mathematical=int(m),agree=a=='1') for t,n,v,m,a in rows]
    assert result['cases']==parsed
    disagreements=[c for c in parsed if not c['agree']]
    assert [(c['type'],c['name'],c['native'],c['mathematical']) for c in disagreements]==[
        ('u64','high_bit',0,3),('u64','maximum',0,3)]
    assert result['profile_disagreements']==[{k:c[k] for k in ('type','name','native','mathematical')} for c in disagreements]
    for dtype,names in NAMES.items():
        cases=[c for c in parsed if c['type']==dtype]
        assert [c['name'] for c in cases]==names
        assert [c['native'] for c in cases]==EXPECTED_MODEL[dtype if dtype!='u64' else 'u64_evaluator']
        assert [c['mathematical'] for c in cases]==EXPECTED_MODEL[dtype if dtype!='u64' else 'u64_logical']
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['dynamic_index_controls']
    assert probe['exit_code']==0 and not probe['stderr'] and 'warning:' not in probe['stdout']
    for name,values in EXPECTED_MODEL.items():
        observed=re.findall(r'^DYNAMIC_INDEX_MODEL '+name+r'=([0-9,]+)$',probe['stdout'],re.M)
        assert observed==[','.join(str(v) for v in values)]
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('DynamicSlice logical/evaluator profiles checked: 18 agreements and 2 preserved u64 disagreements; no rewrite claim')
