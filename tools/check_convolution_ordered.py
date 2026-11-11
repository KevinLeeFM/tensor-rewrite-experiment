"""Check explicit ordered convolution/Dot values and scoped binary32 consequences."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

from ordered_float_examples import expected_rows, multiply

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/convolution-ordered-v2.json'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    manifest=json.loads((root/MANIFEST).read_text())
    for file in manifest['files']:
        assert digest(root/file['path'])==file['sha256'],file['path']
    for predecessor in manifest['predecessor_manifests']:
        assert digest(root/predecessor['path'])==predecessor['sha256']
        frozen=json.loads((root/predecessor['path']).read_text())
        for file in frozen.get('files',frozen.get('model_files',[])):
            assert digest(root/file['path'])==file['sha256'],file['path']
    assert digest(root/'lake-manifest.json')==manifest['lake_manifest_sha256']
    return manifest


def validate_result(result):
    assert result['status']=='kernel_checked_ordered_pointwise_dot_and_binary32_contract'
    for key in ('ordered_contribution_lists_equal','initializer_and_finish_preserved',
                'binary32_ordered_pointwise_proved','binary32_reference_equality_proved'):
        assert result[key] is True,key
    for key in ('semiring_assumed_for_ordered_dot','fma_modeled','exception_flags_observed',
                'changed_cast_placement_equivalence_proved','external_backend_schedule_verified',
                'full_convolution_family_complete','full_numerical_workload_complete',
                'independently_reviewed_statements','code_correspondence_performed'):
        assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['code_correspondence_future_work']
    expected=[dict(name=n,convolution=int(c),dot=int(d),reference=int(s)) for n,c,d,s in expected_rows()]
    assert result['finite_binary32_controls']==expected and len(expected)==12
    assert result['heterogeneous_control']==dict(convolution=94,dot=94)
    assert result['fold_omission_words']==[0,multiply(0x80000000,0x3f800000)]==[0,0x80000000]
    assert result['reversal_words']==[0,0x3f800000]
    assert result['checked_statement_count']==len(result['certificate_axioms'])==15
    assert all(set(a)<={'propext','Quot.sound','Classical.choice'}
               for a in result['certificate_axioms'].values())


def main():
    manifest=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    run=subprocess.run(['lake','env','lean','tests/fixtures/ConvolutionOrderedControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0,run.stdout+run.stderr
    rows=re.findall(r'^ORDERED case=(\w+) conv=(\d+) dot=(\d+) reference=(\d+)$',run.stdout,re.M)
    assert rows==expected_rows(),rows
    heterogeneous=re.findall(r'^HETEROGENEOUS conv=(-?\d+) dot=(-?\d+)$',run.stdout,re.M)
    assert heterogeneous==[('94','94')]
    product=re.findall(r'^ORDERED_WITNESS name=product bits=(\d+)$',run.stdout,re.M)
    assert product==['2147483648']
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for file in theory['files']:
        assert digest(ROOT/file['path'])==file['sha256'],file['path']
    certificates={n:a for n,a in theory['axiom_dependencies'].items()
                  if '.ConvolutionOrdered.' in n or '.ConvolutionFloat.' in n}
    assert set(certificates)==set(manifest['certificates']) and len(certificates)==15
    values={n:int(c) for n,c,_,_ in rows}
    result=dict(status='kernel_checked_ordered_pointwise_dot_and_binary32_contract',
                manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),
                scalar_contract='arbitrary ordered operations; pinned FloatLib binary32 specialization',
                ordered_contribution_lists_equal=True,initializer_and_finish_preserved=True,
                binary32_ordered_pointwise_proved=True,binary32_reference_equality_proved=True,
                semiring_assumed_for_ordered_dot=False,fma_modeled=False,exception_flags_observed=False,
                changed_cast_placement_equivalence_proved=False,external_backend_schedule_verified=False,
                full_convolution_family_complete=False,full_numerical_workload_complete=False,
                independently_reviewed_statements=False,whole_benchmark_records_closed=0,
                code_correspondence_performed=False,code_correspondence_future_work=True,
                checked_statement_count=15,certificate_axioms=certificates,controls_stdout=run.stdout,
                finite_binary32_controls=[dict(name=n,convolution=int(c),dot=int(d),reference=int(s))
                                          for n,c,d,s in rows],
                heterogeneous_control=dict(convolution=94,dot=94),
                fold_omission_words=[values['negative_zero'],int(product[0])],
                reversal_words=[values['finite_order'],values['finite_reverse']],
                oracle='exact rational finite-input rounding; no host floating arithmetic; no NaN policy oracle')
    validate_result(result)
    (ROOT/'reports/convolution-ordered.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Ordered convolution passed:15 statements,12 binary32 rational-oracle controls, '
          'heterogeneous non-associative fold,2 kernel-checked numerical refutations; '
          'external numerical/backend contracts remain open.')


if __name__=='__main__':main()
