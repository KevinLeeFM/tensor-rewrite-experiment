"""Validate and publish the typed mathematical logical family; no source correspondence."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/logical-values-family-v1.json'
LABELS={'not_not':'HandleNot/involution', 'and_zero_left':'HandleAnd/lhs-zero',
        'and_zero_right':'HandleAnd/rhs-zero','or_zero_left':'HandleOr/lhs-zero',
        'or_zero_right':'HandleOr/rhs-zero','xor_zero_left':'HandleXor/lhs-zero',
        'xor_zero_right':'HandleXor/rhs-zero','xor_equal':'HandleXor/equal-inputs',
        'and_true_left':'HandleAnd/lhs-true','and_true_right':'HandleAnd/rhs-true',
        'or_true_left':'HandleOr/lhs-true','or_true_right':'HandleOr/rhs-true'}


def sha(path):return hashlib.sha256(path.read_bytes()).hexdigest()


def profile_rows(stdout):
    rows=re.findall(r'^LOGICAL_PROFILE (predicate|word_all_widths) (\w+)$',stdout,re.M)
    assert len(rows)==len(set(rows))==20
    assert sum(domain=='predicate' for domain,_ in rows)==12
    assert sum(domain=='word_all_widths' for domain,_ in rows)==8
    assert {key for _,key in rows}==set(LABELS)
    assert all('true' not in key for domain,key in rows if domain=='word_all_widths')
    return [dict(id=domain+'/'+key, domain=domain,rule=key,
                 side_condition='inputs[0] = inputs[1]' if key=='xor_equal' else 'True',
                 candidate_benchmark_label=LABELS[key],
                 label_correspondence_certified=False) for domain,key in rows]


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--freeze-family',action='store_true')
    args=parser.parse_args()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,(build.stdout+build.stderr)[-5000:]
    audit=subprocess.run(['lake','env','lean','tests/fixtures/LogicalFamilyAudit.lean'],
                         cwd=ROOT,text=True,capture_output=True)
    assert audit.returncode==0,audit.stdout+audit.stderr
    profiles=profile_rows(audit.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    certificates={name:axioms for name,axioms in theory['axiom_dependencies'].items()
                  if '.LogicalFamily.' in name}
    assert len(certificates)==6
    assert all(set(a)<={'propext','Quot.sound','Classical.choice'} for a in certificates.values())
    paths=['TensorRewrite/Theory/LogicalFamily.lean','TensorRewrite/Theory/LogicalFamilyProof.lean']
    frozen=dict(schema=1,family='typed_logical_values_v1',profile_units=profiles,
                profile_unit_count=20,model_files=[dict(path=p,sha256=sha(ROOT/p)) for p in paths],
                scope='predicate or arbitrary-width word values; arbitrary finite rank/extents; '
                      'pure expression semantics; equality condition on equal-input xor',
                mathematical_family_denominator_frozen=True,
                full_mathematical_workload_denominator_frozen=False,
                code_correspondence='future_work')
    target=ROOT/MANIFEST
    if args.freeze_family:
        if target.exists():raise ValueError('family v1 already frozen; use a new version for changes')
        target.write_text(json.dumps(frozen,indent=2)+'\n')
    else:assert json.loads(target.read_text())==frozen,'frozen family/model changed'
    controls={}
    for fixture in ['InvalidLogicalWordTrue','InvalidLogicalXorEqual']:
        run=subprocess.run(['lake','env','lean','tests/fixtures/'+fixture+'.lean'],
                           cwd=ROOT,text=True,capture_output=True)
        assert run.returncode!=0 and 'error:' in run.stdout,run.stdout+run.stderr
        if fixture=='InvalidLogicalWordTrue':assert 'andTrueRight' in run.stdout
        else:assert 'rfl' in run.stdout and 'false' in run.stdout
        controls[fixture]=dict(exit_code=run.returncode,stdout=run.stdout,stderr=run.stderr)
    result=dict(status='kernel_complete_declared_mathematical_value_family',
                profile_unit_count=20,covered_candidate_benchmark_labels=sorted(set(LABELS.values())),
                profile_units=profiles,whole_benchmark_records_closed=0,
                certificate_axioms=certificates,independent_statement_review='pending',
                observations='pure tensor values only; effects/schedules/layout outside this family',
                code_correspondence_performed=False,code_correspondence_future_work=True,
                manifest=MANIFEST,manifest_sha256=sha(target),negative_controls=controls,
                audit_stdout=audit.stdout)
    (ROOT/'reports/logical-values-family.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Logical family passed:20 mathematical value profiles,12 candidate labels; '
          'soundness, complete duplicate-free enumeration and all-width uniformity checked.')


if __name__=='__main__':main()
