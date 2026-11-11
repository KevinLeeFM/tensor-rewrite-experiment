"""Check ordered window semantics and unit-window affine gathers; no native pass work."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from reduction_window_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/reduction-window-v1.json'
DOMAINS='census/reduction-window-domains-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate_domains(domains):
    assert domains['status']=='partial_window_model_evidence_not_a_frozen_denominator'
    assert domains['mathematical_obligation_denominator'] is None
    assert domains['source_guards_adopted_as_proof_assumptions'] is False
    batch=json.loads((ROOT/domains['retained_batch']).read_text())
    assert digest(ROOT/domains['retained_batch'])==domains['retained_batch_sha256']
    expected_ids={r['id'] for r in batch['cases'] if r['id'].startswith('HandleReduceWindow/')}
    ids=[r['benchmark_id'] for r in domains['records']]
    assert len(ids)==len(set(ids))==len(expected_ids)==31 and set(ids)==expected_ids
    for row in domains['records']:
        assert row['remaining_mathematical_partitions']
        assert row['whole_record_closed'] is False
        assert row['independent_statement_review']=='pending'
        assert row['code_correspondence']=='future_work'


def check_inputs():
    manifest=json.loads((ROOT/MANIFEST).read_text())
    for row in manifest['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==manifest['lake_manifest_sha256']
    validate_domains(json.loads((ROOT/DOMAINS).read_text()))
    return manifest


def validate_result(result):
    manifest=check_inputs()
    assert result['status']=='kernel_checked_ordered_window_and_unit_affine_gather'
    assert result['scalar_contract']=='arbitrary_ordered_operations_with_explicit_padding_laws'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    assert result['checked_statement_count']==len(result['certificate_axioms'])==29
    assert set(result['certificate_axioms'])==set(manifest['certificates'])
    assert result['counterexample_certificates']==manifest['counterexample_certificates']
    assert len(result['counterexample_certificates'])==2
    assert all(set(a)<=ALLOWED for a in result['certificate_axioms'].values())
    counts,rows=expected()
    assert result['profile_counts']==counts and result['controls']==rows
    assert result['semantic_profile_count']==len(counts)==15
    assert result['semantic_output_count']==len(rows)==45
    assert result['unit_affine_requires_undilated_input'] is True
    assert result['invalid_samples_are_folded'] is True
    assert result['source_guards_adopted_as_proof_assumptions'] is False
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None
    for key in ('ieee_add_zero_identity_supplied','separate_slice_pad_graph_equivalence_proved',
                'all_window_rewrites_proved','full_workload_complete','independently_reviewed_statements',
                'benchmark_correspondence_certified','code_correspondence_performed'):
        assert result[key] is False,key


def main():
    manifest=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ReductionWindowControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0,run.stdout+run.stderr
    assert 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts=[dict(name=n,outputs=int(o),window=int(w),unit_affine=e=='true')
            for n,o,w,e in re.findall(r'^WINDOW_COUNT name=(\w+) outputs=(\d+) window=(\d+) '
                                      r'affine=(true|false)$',run.stdout,re.M)]
    pattern=(r'^WINDOW name=(\w+) output=(\d+) trace=(\[[\d, -]*\]) sum=(-?\d+) '
             r'zero=(-?\d+) decimal=(-?\d+) min=(-?\d+) max=(-?\d+) gather=(-?\d+)$')
    rows=[dict(name=n,output=int(o),trace=json.loads(t),sum=int(s),zero=int(z),decimal=int(d),
               min=int(l),max=int(h),gather=int(g))
          for n,o,t,s,z,d,l,h,g in re.findall(pattern,run.stdout,re.M)]
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.ReductionWindow.' in n}
    result=dict(status='kernel_checked_ordered_window_and_unit_affine_gather',manifest=MANIFEST,
                manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
                counterexample_certificates=manifest['counterexample_certificates'],
                checked_statement_count=len(axioms),profile_counts=counts,controls=rows,
                semantic_profile_count=len(counts),semantic_output_count=len(rows),control_stdout=run.stdout,
                scalar_contract='arbitrary_ordered_operations_with_explicit_padding_laws',
                unit_affine_requires_undilated_input=True,invalid_samples_are_folded=True,
                source_guards_adopted_as_proof_assumptions=False,ieee_add_zero_identity_supplied=False,
                separate_slice_pad_graph_equivalence_proved=False,all_window_rewrites_proved=False,
                full_workload_complete=False,independently_reviewed_statements=False,
                benchmark_correspondence_certified=False,code_correspondence_performed=False,
                whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    validate_result(result)
    (ROOT/'reports/reduction-window.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Window model passed:29 statements,15 profiles,45 oracle outputs; '
          'separate Slice/Pad, full-span/composition and numerical partitions remain open.')


if __name__=='__main__':main()
