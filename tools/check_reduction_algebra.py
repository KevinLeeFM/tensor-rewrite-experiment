"""Check bounded reduction algebra and the full retained reduction-domain worksheet."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from reduction_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/reduction-algebra-v2.json'
WORKSHEET='census/reduction-mathematical-domains-v2.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def validate_domains(worksheet):
    assert worksheet['status']=='mathematical_domain_worksheet_not_a_frozen_obligation_denominator'
    assert worksheet['classification_groups_are_not_a_frozen_family_denominator'] is True
    assert worksheet['mathematical_obligation_denominator'] is None
    assert worksheet['independently_reviewed'] is False
    assert worksheet['code_correspondence_performed'] is False
    assert worksheet['source_guards_adopted_as_proof_assumptions'] is False
    assert digest(ROOT/worksheet['retained_batch'])==worksheet['retained_batch_sha256']
    cases=json.loads((ROOT/worksheet['retained_batch']).read_text())['cases']
    ids=[name for family in worksheet['families'] for name in family['benchmark_ids']]
    assert len(ids)==len(set(ids))==len(cases)==worksheet['benchmark_record_count']==60
    assert set(ids)=={row['id'] for row in cases}
    assert len(worksheet['families'])==worksheet['classification_group_count']==19
    for family in worksheet['families']:
        assert family['mathematical_target'] and family['declared_premises']
        assert family['remaining_mathematical_partitions']
        assert family['whole_record_closed'] is False


def check_inputs():
    manifest=json.loads((ROOT/MANIFEST).read_text())
    for row in manifest['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==manifest['lake_manifest_sha256']
    worksheet=json.loads((ROOT/WORKSHEET).read_text());validate_domains(worksheet)
    return manifest


def validate_result(result):
    manifest=check_inputs()
    assert result['status']=='kernel_checked_bounded_reduction_algebra'
    assert result['scalar_contract']=='explicit_absorption_or_exact_additive_algebra'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    assert result['checked_statement_count']==len(result['certificate_axioms'])==27
    assert set(result['certificate_axioms'])==set(manifest['certificates'])
    assert result['counterexample_certificates']==manifest['counterexample_certificates']
    assert len(result['counterexample_certificates'])==3
    for axioms in result['certificate_axioms'].values():assert set(axioms)<=ALLOWED
    counts,rows=expected()
    assert result['profile_counts']==counts and result['controls']==rows
    assert result['semantic_profile_count']==len(counts)==9
    assert result['semantic_output_count']==len(rows)==20
    assert result['domain_worksheet']==WORKSHEET
    assert result['domain_worksheet_sha256']==digest(ROOT/WORKSHEET)
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None
    for key in ('ieee_addition_algebra_assumed','window_geometry_proved','full_reduction_family_complete',
                'full_workload_complete','independently_reviewed_statements',
                'benchmark_correspondence_certified','code_correspondence_performed'):
        assert result[key] is False,key


def main():
    manifest=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ReductionAlgebraControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0,run.stdout+run.stderr
    assert 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts=[dict(name=n,outputs=int(o),fiber=int(f)) for n,o,f in re.findall(
        r'^REDUCTION_COUNT name=(\w+) outputs=(\d+) fiber=(\d+)$',run.stdout,re.M)]
    pattern=(r'^REDUCTION name=(\w+) output=(\d+) fiber=(\[[\d, -]*\]) '
             r'coords=(\[[\d, -]*\]) sum=(-?\d+) neg=(-?\d+) constant=(-?\d+) '
             r'min=(-?\d+) max=(-?\d+)$')
    rows=[dict(name=n,output=int(o),fiber=json.loads(f),coords=json.loads(c),sum=int(s),
               neg=int(v),constant=int(k),min=int(l),max=int(h))
          for n,o,f,c,s,v,k,l,h in re.findall(pattern,run.stdout,re.M)]
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items()
            if '.ReductionAlgebra.' in n or '.ReductionFiber.' in n}
    result=dict(status='kernel_checked_bounded_reduction_algebra',manifest=MANIFEST,
                manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
                counterexample_certificates=manifest['counterexample_certificates'],
                checked_statement_count=len(axioms),profile_counts=counts,controls=rows,
                semantic_profile_count=len(counts),semantic_output_count=len(rows),control_stdout=run.stdout,
                scalar_contract='explicit_absorption_or_exact_additive_algebra',
                ieee_addition_algebra_assumed=False,window_geometry_proved=False,
                full_reduction_family_complete=False,full_workload_complete=False,
                independently_reviewed_statements=False,benchmark_correspondence_certified=False,
                code_correspondence_performed=False,code_correspondence_future_work=True,
                whole_benchmark_records_closed=0,mathematical_obligation_denominator=None,
                domain_worksheet=WORKSHEET,domain_worksheet_sha256=digest(ROOT/WORKSHEET))
    validate_result(result)
    (ROOT/'reports/reduction-algebra.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Reduction algebra: 27 checked statements; 9 profiles,20 oracle outputs; '
          'all60 retained reduction records diagnosed, full family remains open.')


if __name__=='__main__':main()
