"""Check the mathematical convolution model, declared assumptions and finite semantic controls."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
from convolution_examples import expected_rows

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/convolution-model-v2.json'


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def validate_result(result):
    assert result['status']=='kernel_checked_convolution_model_and_partial_algebra'
    assert result['scalar_contract']=='exact_semiring'
    assert not result['ieee_accumulation_contract_proved']
    assert not result['precision_conversions_modeled'] and not result['physical_layout_modeled']
    assert not result['full_convolution_family_complete']
    assert result['whole_benchmark_records_closed']==0
    assert not result['code_correspondence_performed'] and result['code_correspondence_future_work']
    assert result['checked_model_theorems']==20
    expected=[dict(name=name,value=None if value=='none' else int(value)) for name,value in expected_rows()]
    assert result['controls']==expected and len(expected)==22
    assert len(result['certificate_axioms'])==20
    assert all(set(a)<={'propext','Quot.sound','Classical.choice'}
               for a in result['certificate_axioms'].values())
    assert set(result['negative_controls'])=={
        'InvalidConvolutionFloatSemiring','InvalidConvolutionStride'}
    assert all(r['exit_code']!=0 for r in result['negative_controls'].values())


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--freeze-model',action='store_true')
    args=parser.parse_args()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,(build.stdout+build.stderr)[-5000:]
    controls=subprocess.run(['lake','env','lean','tests/fixtures/ConvolutionControls.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert controls.returncode==0,controls.stdout+controls.stderr
    rows=re.findall(r'^CONV_MODEL case=(\w+) value=(none|-?[0-9]+)$',controls.stdout,re.M)
    assert rows==expected_rows(),rows
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    certificates={name:axioms for name,axioms in theory['axiom_dependencies'].items()
                  if '.Convolution.' in name}
    assert len(certificates)==20
    paths=['TensorRewrite/Theory/Convolution.lean','TensorRewrite/Theory/ConvolutionLemmas.lean',
           'TensorRewrite/Theory/ConvolutionAlgebra.lean']
    model=dict(schema=1,model='factored_static_exact_convolution_v2',
               scalar_contract='exact_semiring',model_files=[dict(path=p,sha256=sha(ROOT/p)) for p in paths],
               geometry='arbitrary spatial rank; positive stride/base/kernel dilations; signed low/high '
                        'padding; kernel reversal; bounded batch/feature groups and channels',
               grouping='explicit batch group, feature group and output feature axes; no layout normalizer',
               sampling='zero contributions for out-of-range positions and base-dilation holes',
               output_shape='derived per axis from dilated extents and signed padding',
               semantic_statement_review='independent review pending',
               precision_conversions_modeled=False,physical_layout_modeled=False,
               ieee_accumulation_contract_proved=False,full_convolution_family_complete=False,
               code_correspondence='future_work')
    target=ROOT/MANIFEST
    if args.freeze_model:
        if target.exists():raise ValueError('convolution model already frozen; create a new version')
        target.write_text(json.dumps(model,indent=2)+'\n')
    else:assert json.loads(target.read_text())==model,'frozen model/assumptions changed'
    negatives={}
    for fixture in ('InvalidConvolutionFloatSemiring','InvalidConvolutionStride'):
        run=subprocess.run(['lake','env','lean','tests/fixtures/'+fixture+'.lean'],
                           cwd=ROOT,text=True,capture_output=True)
        assert run.returncode!=0 and re.search(r'error(?:\([^\n]*\))?:',run.stdout),run.stdout+run.stderr
        if fixture.endswith('FloatSemiring'):assert 'Semiring' in run.stdout and 'synthesize' in run.stdout
        else:assert '0 < 0' in run.stdout
        negatives[fixture]=dict(exit_code=run.returncode,stdout=run.stdout,stderr=run.stderr)
    result=dict(status='kernel_checked_convolution_model_and_partial_algebra',
                scalar_contract='exact_semiring',checked_model_theorems=20,
                certificate_axioms=certificates,controls=[dict(name=n,value=None if v=='none' else int(v))
                                                         for n,v in rows],
                controls_stdout=controls.stdout,negative_controls=negatives,
                ieee_accumulation_contract_proved=False,precision_conversions_modeled=False,
                physical_layout_modeled=False,full_convolution_family_complete=False,
                whole_benchmark_records_closed=0,code_correspondence_performed=False,
                code_correspondence_future_work=True,independent_statement_review='pending',
                manifest=MANIFEST,manifest_sha256=sha(target))
    validate_result(result)
    (ROOT/'reports/convolution-model.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Convolution model passed:20 mathematical theorems,22 semantic vectors,2 negative controls; '
          'exact semiring only; full family and IEEE theory remain open.')


if __name__=='__main__':main()
