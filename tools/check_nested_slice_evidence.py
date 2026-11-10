"""Keep logical composition and evaluator-relative rewrite evidence distinct."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
CASE='HandleDynamicSlice/nested'
LOGICAL='arbitrary finite rank and bounded static extents; mathematical decoded starts'
EVALUATOR='observed s64 conversion for DynamicSlice; typed unsigned HLO clamps; 10 to 6 to 2 shape chain'
VALUES={'inner_high':(1,5),'outer_high':(1,5),'both_high':(0,8),'max_signed':(8,8),
        'signed_bounds':(4,4),'inner_high_mixed':(1,5),'outer_high_mixed':(0,4),'u32_max':(8,8)}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/nested-slice-contract.json').read_text())
    assert contract['status']=='logical_composition_proved_evaluator_preservation_refuted_source_contract_open'
    assert contract['source_case']==CASE and contract['accepted_source_rewrites']==0
    assert contract['logical_profile']==LOGICAL and contract['evaluator_profile']==EVALUATOR
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=contract['source_contract']
    body='\n'.join((root/source['path']).read_text().splitlines()[source['line']-1:source['end_line']])
    assert hashlib.sha256(body.encode()).hexdigest()==source['source_body_sha256']
    assert 'FitsInIntegralType' in body and 'CreateConvert' in body and 'kAdd' in body
    cases=json.loads((root/'census/tensor-index-cases.json').read_text())['cases']
    case=next(c for c in cases if c['id']==CASE)
    assert case['proof'] is None and len(case['additional_replacement_sites'])==1
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    group=proofs['nested_slice']
    for key in ('source_case','accepted_source_rewrites','logical_profile','evaluator_profile',
                'logical_rule_theorems','evaluator_profile_certificates','native_evidence'):
        assert group[key]==contract[key]
    assert len(contract['support_theorems'])==3
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    assert contract['logical_rule_theorems']==['TensorRewrite.Pilot.DynamicIndex.sliceTensor_compose']
    assert contract['evaluator_profile_certificates']==['TensorRewrite.Pilot.NestedUnsigned64.'+name
        for name in ('inner_high_changes','outer_high_changes','both_high_changes','not_universally_preserving')]


def check_archive(root=ROOT):
    folder=root/'reports/nested-slice-replay-v2'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_nested_slice_evaluator_value_changes'
    assert result['xla_full_pass_run'] and result['xla_operator_evaluator_run']
    assert result['test_passed'] and result['exit_code']==0
    assert result['interpretation']=='observed evaluator preservation; backend contract not established'
    assert '--nocache_test_results' in result['command']
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    assert re.fullmatch('[0-9a-f]{64}',result['binary_sha256'])
    assert len(result['files'])==6
    assert {Path(f['path']).name for f in result['files']}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for file in result['files']:
        path=root/file['path'];assert path.parent==folder
        assert hashlib.sha256(path.read_bytes()).hexdigest()==file['sha256']
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^NESTED_SLICE_RESULT case=(\w+) run_pass=([01]) changed=([01]) before=(\d+) after=(\d+) rewritten_verified=1$',log,re.M)
    expected=[(name,str(run),str(run),str(before),str(after if run else before))
              for name,(before,after) in VALUES.items() for run in (0,1)]
    assert rows==expected
    assert result['cases']==[dict(name=n,run_pass=p=='1',changed=c=='1',before=int(b),after=int(a),rewritten_verified=True)
                             for n,p,c,b,a in rows]
    assert sum(p=='1' and b!=a for n,p,c,b,a in rows)==5
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['nested_slice_controls']
    assert probe['exit_code']==0 and not probe['stderr']
    assert probe['stdout']=='NESTED_SLICE_MODEL before=1,1,0\nNESTED_SLICE_MODEL after=5,5,8\n'
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==1 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('Nested DynamicSlice logical proof and evaluator-relative changes checked separately: 8 pass cases, 8 no-pass controls')
