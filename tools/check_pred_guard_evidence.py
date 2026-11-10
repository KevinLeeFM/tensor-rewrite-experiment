"""Offline source/model/native PRED guard checks; no new handler or pass execution."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
WRAPPERS=['Broadcast','Copy','DynamicSlice','Reshape','Reverse','Slice','Transpose']
MODEL_WRAPPERS=['broadcast','copy','dynamicSlice','reshape','reverse','slice','transpose']
NATIVE_NAMES={'literal','broadcast','copy','dynamic_slice','reshape','reverse','slice','transpose','opaque_not','nonuniform'}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/pred-guard-contract.json').read_text())
    assert contract['source_wrapper_whitelist']==WRAPPERS
    assert contract['model_wrapper_names']==MODEL_WRAPPERS
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['accepted_source_rewrites']==0
    assert contract['semantic_track']=='PRED finite storage and pure total index pullbacks'
    assert contract['native_scope']=='direct_public_HandleAnd_and_LiteralBase_IsAll_not_full_pass'
    full=json.loads((root/'census/full-call-inventory.json').read_text())
    function=next(f for f in full['functions'] if f['id']==contract['wrapper_function_id'])
    assert function['name']=='UnwrapToConstant'
    source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()
    body=source[function['byte_start']:function['byte_end']].decode()
    assert [n for n in re.findall(r'case HloOpcode::k(\w+):',body) if n!='Constant']==WRAPPERS
    assert hashlib.sha256(body.encode()).hexdigest()==contract['wrapper_source_sha256']
    model=(root/'TensorRewrite/Pilot/ConstantGuard.lean').read_text()
    enum=model.split('inductive Wrapper where',1)[1].split('deriving',1)[0]
    assert re.findall(r'^  \| (\w+)\s*$',enum,re.M)==MODEL_WRAPPERS
    manifest=json.loads((root/'sources/constant-guard-contract-manifest.json').read_text())
    assert manifest['source_commit']==contract['source_commit']
    for item in manifest['files']:
        assert hashlib.sha256((root/item['path']).read_bytes()).hexdigest()==item['sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    assert proofs['constant_guard']['bridge_theorems']==[contract['graph_bridge_theorem']]
    assert proofs['constant_guard']['accepted_source_rewrites']==0


def check_archive(root=ROOT):
    folder=root/'reports/pred-guard-replay-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_pred_guard_handler_and_literal_controls_passed'
    assert result['test_passed'] and result['exit_code']==0 and result['xla_handler_run']
    assert result['xla_full_pass_run'] is False
    assert result['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    source=root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
    assert hashlib.sha256(source.read_bytes()).hexdigest()==result['pass_source_sha256']
    files=result['files']
    assert len(files)==6 and {Path(f['path']).name for f in files}=={'fixture.cc','BUILD','events.json','build.log','test.log','test.xml'}
    for f in files:
        p=root/f['path'];assert p.parent==folder
        assert hashlib.sha256(p.read_bytes()).hexdigest()==f['sha256']
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^PRED_GUARD_RESULT wrapper=(\w+) expected_changed=([01]) changed=([01]) before_after_equal=1 root_parameter=([01])$',log,re.M)
    assert len(rows)==10 and {r[0] for r in rows}==NATIVE_NAMES
    assert all(e==c==p==('0' if n in ('opaque_not','nonuniform') else '1') for n,e,c,p in rows)
    expected=sorted((n,e=='1',c=='1',p=='1') for n,e,c,p in rows)
    assert sorted((c['wrapper'],c['expected_changed'],c['changed'],c['root_parameter']) for c in result['cases'])==expected
    assert all(c['before_after_equal'] for c in result['cases'])
    assert result['literal_boundary_control_passed']
    assert 'PRED_GUARD_LITERAL empty_matches_both=1 mixed_matches_neither=1 ones_only_one=1 value_two_rejected=1' in log
    assert log.count('ORIGINAL_HLO')==log.count('REWRITTEN_HLO')==10
    fixture=(folder/'fixture.cc').read_text()
    assert 'visitor.HandleAnd(module->entry_computation()->root_instruction())' in fixture
    assert 'simplifier.Run(' not in fixture
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==2
    assert not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract()
    check_archive()
    print('PRED guard source/model whitelist and native handler/literal archives checked; no new execution or full-pass claim')
