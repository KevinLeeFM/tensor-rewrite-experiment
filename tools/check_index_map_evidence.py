"""Compare checked-model probes with archived native operator evaluations."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
EXPECTED={'BROADCAST':'5','SLICE':'9,12,23,26,37,40','EMPTY':'0','LARGE_STRIDE':'1'}


def decode_observations(text,model=False):
    prefix='INDEX_MAP_MODEL_' if model else 'INDEX_MAP_'
    fields={'BROADCAST':'selected','SLICE':'values','EMPTY':'elements','LARGE_STRIDE':'value'}
    result={}
    for kind,field in fields.items():
        rows=re.findall(r'^'+prefix+kind+r'\b[^\n]*\b'+field+r'=([0-9,]+)$',text,re.M)
        assert len(rows)==1
        result[kind]=rows[0]
    return result


def check_contract(root=ROOT):
    contract=json.loads((root/'census/concrete-index-contract.json').read_text())
    assert contract['status']=='kernel_checked_static_math_maps_not_cpp_extraction'
    assert contract['profile']=='static bounded shapes; mathematical signed attributes and arithmetic'
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['operator_names']==['Broadcast','Slice'] and contract['accepted_source_rewrites']==0
    assert contract['native_scope']=='operator_evaluator_only_no_handler_or_pass'
    assert [c['id'] for c in contract['contracts']]==['hlo-broadcast-shape','hlo-broadcast-order','static-slice-shape']
    for c in contract['contracts']:
        body='\n'.join((root/c['path']).read_text().splitlines()[c['line']-1:c['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==c['source_body_sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert set(contract['support_theorems'])<=set(proofs['support_theorems'])
    assert proofs['concrete_index_maps']['accepted_source_rewrites']==0
    assert proofs['concrete_index_maps']['profile']==contract['profile']


def check_archive(root=ROOT):
    folder=root/'reports/index-map-evaluator-v1'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='real_xla_nonuniform_index_map_examples_passed'
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
    assert decode_observations(log)==EXPECTED
    assert sorted(result['observations'])==sorted(line for line in log.splitlines() if line.startswith('INDEX_MAP_'))
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['index_map_controls']
    assert probe['exit_code']==0 and not probe['stderr'] and 'warning:' not in probe['stdout']
    assert decode_observations(probe['stdout'],model=True)==EXPECTED
    fixture=(folder/'fixture.cc').read_text()
    assert 'ParseAndReturnVerifiedModule' in fixture and 'evaluator.Evaluate' in fixture
    assert 'AlgebraicSimplifier' not in fixture
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==4
    assert not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract()
    check_archive()
    print('Concrete static-map source contracts and Lean/native coordinates agree; archived operator evaluation only')
