"""Check a derived, typed Map/Slice/Pad graph without compiler/source correspondence."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from slice_pad_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/slice-pad-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    manifest=json.loads((ROOT/MANIFEST).read_text())
    for row in manifest['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==manifest['lake_manifest_sha256']
    assert manifest['unit_window_conditions']=='unit kernel; undilated input; op(initial,padding)=padding'
    assert manifest['slice_count_inferred_from_ordinary_attributes'] is True
    assert manifest['shape_or_index_equivalence_postulated'] is False
    return manifest


def validate_result(result):
    manifest=check_inputs()
    assert result['status']=='kernel_checked_constructed_slice_pad_factorization'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    assert result['checked_statement_count']==len(result['certificate_axioms'])==28
    assert set(result['certificate_axioms'])==set(manifest['certificates'])
    assert result['counterexample_certificates']==manifest['counterexample_certificates']
    assert len(result['counterexample_certificates'])==2
    assert all(set(a)<=ALLOWED for a in result['certificate_axioms'].values())
    axes,profiles,rows=expected()
    assert result['axis_controls']==axes and result['profile_counts']==profiles
    assert result['controls']==rows
    assert result['axis_profile_count']==len(axes)==675
    assert result['tensor_profile_count']==len(profiles)==15
    assert result['tensor_output_count']==len(rows)==45
    for key in ('separate_slice_pad_graph_equivalence_proved','slice_attributes_well_formed',
                'output_shape_equality_derived','unit_window_side_conditions_retained'):
        assert result[key] is True,key
    for key in ('shape_or_index_equivalence_postulated','ieee_zero_identity_supplied',
                'all_window_rewrites_proved','full_workload_complete',
                'independently_reviewed_statements','benchmark_correspondence_certified',
                'code_correspondence_performed'):
        assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    manifest=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/SlicePadControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0,run.stdout+run.stderr
    assert 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    pattern=(r'^FACTOR_AXIS n=(\d+) outputs=(\d+) stride=(\d+) low=(-?\d+) '
             r'first=(\d+) last=(\d+) count=(\d+) start=(\d+) limit=(\d+) shape=(\d+) legal=(true|false)$')
    axes=[dict(n=int(n),outputs=int(o),stride=int(s),low=int(l),first=int(a),last=int(b),
               count=int(c),start=int(i),limit=int(j),shape=int(k),legal=e=='true')
          for n,o,s,l,a,b,c,i,j,k,e in re.findall(pattern,run.stdout,re.M)]
    profiles=[dict(name=n,outputs=int(o),eligible=e=='true') for n,o,e in re.findall(
        r'^FACTOR_COUNT name=(\w+) outputs=(\d+) eligible=(true|false)$',run.stdout,re.M)]
    pattern=(r'^FACTOR name=(\w+) output=(\d+) graph=(-?\d+) gather=(-?\d+) '
             r'boolean=(true|false) min=(-?\d+) max=(-?\d+) zero_graph=(-?\d+) zero_window=(-?\d+)$')
    rows=[dict(name=n,output=int(o),graph=int(g),gather=int(a),boolean=e=='true',minimum=int(l),
               maximum=int(h),zero_graph=int(z),zero_window=int(w))
          for n,o,g,a,e,l,h,z,w in re.findall(pattern,run.stdout,re.M)]
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.SlicePad.' in n}
    result=dict(status='kernel_checked_constructed_slice_pad_factorization',manifest=MANIFEST,
                manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
                checked_statement_count=len(axioms),counterexample_certificates=manifest['counterexample_certificates'],
                axis_controls=axes,profile_counts=profiles,controls=rows,control_stdout=run.stdout,
                axis_profile_count=len(axes),tensor_profile_count=len(profiles),tensor_output_count=len(rows),
                separate_slice_pad_graph_equivalence_proved=True,slice_attributes_well_formed=True,
                output_shape_equality_derived=True,unit_window_side_conditions_retained=True,
                shape_or_index_equivalence_postulated=False,ieee_zero_identity_supplied=False,
                all_window_rewrites_proved=False,full_workload_complete=False,
                independently_reviewed_statements=False,benchmark_correspondence_certified=False,
                code_correspondence_performed=False,whole_benchmark_records_closed=0,
                mathematical_obligation_denominator=None)
    validate_result(result)
    (ROOT/'reports/slice-pad.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Slice/Pad factorization:28 checked statements;675 axis profiles;15 tensor profiles/45 '
          'outputs agree; whole workload remains open.')


if __name__=='__main__':main()
