"""Check dense cell-layout proofs without promoting the separate tiled-size diagnostic."""
import hashlib
import json
from pathlib import Path
import re
import xml.etree.ElementTree as ET

ROOT=Path(__file__).resolve().parents[1]
PROFILE='static untiled dense arrays; same fixed cell type; mathematical cell addresses; tiles, packing and memory spaces separate'
SCOPE='dense handler/pass/no-rewrite runs; tiled ArraySize diagnostic uses direct handler only'
TILED='ArraySize verifier policy; backend adoption and tiled value semantics pending'
CASES={'default_affine':(True,True,6,3),'column_affine':(True,True,6,3),
       'wrong_layout':(True,False,6,3),'insensitive':(False,True,6,3),'rank3_cycle':(True,True,24,100)}


def check_contract(root=ROOT):
    contract=json.loads((root/'census/dense-layout-contract.json').read_text())
    assert contract['status']=='kernel_checked_dense_cell_layout_not_full_source_acceptance'
    assert contract['source_commit']==json.loads((root/'sources/manifest.json').read_text())['xla_commit']
    assert contract['profile']==PROFILE and contract['native_scope']==SCOPE
    assert contract['accepted_source_rewrites']==0
    assert contract['tiled_boundary_scope']==TILED and contract['tiled_diagnostic_is_lean_refutation'] is False
    manifest=json.loads((root/'sources/layout-storage-contract-manifest.json').read_text())
    assert manifest['source_commit']==contract['source_commit']
    for record in manifest['files']:
        assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256']
    assert [r['id'] for r in contract['contracts']]==['transpose-physical-guard','transpose-handler-helper',
        'transpose-bitcast-branch','bitcast-verifier','verifier-size-options','tiled-array-size','bitcast-evaluator']
    for record in contract['contracts']:
        body='\n'.join((root/record['path']).read_text().splitlines()[record['line']-1:record['end_line']])
        assert hashlib.sha256(body.encode()).hexdigest()==record['source_body_sha256']
    proofs=json.loads((root/'census/pilot-value-proofs.json').read_text())
    assert len(contract['support_theorems'])==10 and set(contract['support_theorems'])<=set(proofs['support_theorems'])
    for key in ('accepted_source_rewrites','profile','source_case','native_scope','native_evidence',
                'tiled_boundary_scope','tiled_diagnostic_is_lean_refutation'):
        assert proofs['dense_layout'][key]==contract[key]
    rule=contract['rule']
    assert rule in proofs['rules'] and rule['source_rewrite_accepted'] is False
    assert rule['theorem']=='TensorRewrite.Pilot.DenseLayout.transpose_eq_bitcast'
    assert rule['semantic_track']==PROFILE
    assert rule['source_partition']=='untiled dense same-cell-type subcase; actual minor-order array equation explicit'
    assert rule['status']=='pilot_value_proof_pending_source_graph_review'
    source=next(c for c in json.loads((root/'census/shape-cases.json').read_text())['cases'] if c['id']==rule['source_case'])
    assert source['proof'] is None


def check_archive(root=ROOT):
    folder=root/'reports/transpose-bitcast-replay-v2'
    result=json.loads((folder/'result.json').read_text())
    assert result['status']=='dense_transpose_preserved_tiled_arraysize_boundary_observed'
    assert result['test_passed'] and result['exit_code']==0
    assert result['xla_full_pass_run'] and result['xla_handler_run']
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
    log=(folder/'test.log').read_text()
    rows=re.findall(r'^TRANSPOSE_BITCAST_RESULT case=(\w+) mode=(control|handler|pass) sensitive=([01]) compatible=([01]) changed=([01]) checked=(\d+) selected=(\d+) rewritten_verified=1$',log,re.M)
    expected=[(n,m,str(int(sensitive)),str(int(compatible)),str(int(m!='control' and sensitive and compatible)),str(count),str(selected))
              for n,(sensitive,compatible,count,selected) in CASES.items() for m in ('control','handler','pass')]
    assert rows==expected
    assert result['cases']==[dict(name=n,mode=m,sensitive=s=='1',compatible=c=='1',changed=h=='1',checked=int(k),selected=int(v),rewritten_verified=True)
                             for n,m,s,c,h,k,v in rows]
    tiled=re.findall(r'^TILED_ARRAY_SIZE_RESULT input_bytes=(\d+) output_bytes=(\d+) compatible=([01]) changed=([01]) original_verified=([01]) rewritten_verified=([01]) operator_evaluation=([01])$',log,re.M)
    assert tiled==[('32','64','1','1','1','0','0')]
    assert 'Bitcast cannot have different shape sizes' in log
    assert result['tiled_boundary']==dict(input_bytes=32,output_bytes=64,compatible=True,changed=True,
        original_verified=True,rewritten_verified=False,operator_evaluation=False,scope=TILED)
    model=json.loads((root/'reports/pilot-values.json').read_text())
    probe=model['checks']['dense_layout_controls']
    assert probe['exit_code']==0 and not probe['stderr']
    assert probe['stdout']=='DENSE_LAYOUT_MODEL correct=0,3,1,4,2,5\nDENSE_LAYOUT_MODEL wrong=0,1,2,3,4,5\nDENSE_LAYOUT_MODEL rank3_selected=100 address=12\nDENSE_LAYOUT_MODEL guards=true,false,true\n'
    events=[json.loads(line) for line in (folder/'events.json').read_text().splitlines()]
    assert any(e.get('finished',{}).get('overallSuccess') for e in events)
    assert any(e.get('testResult',{}).get('status')=='PASSED' for e in events)
    xml=ET.parse(folder/'test.xml')
    assert len(xml.findall('.//testcase'))==2 and not xml.findall('.//failure') and not xml.findall('.//error')


if __name__=='__main__':
    check_contract();check_archive()
    print('Dense transpose/bitcast values checked in 15 runs; separate tiled ArraySize verifier rejection preserved')
