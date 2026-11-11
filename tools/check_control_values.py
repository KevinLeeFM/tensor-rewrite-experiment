"""Replay exact pure control profiles and keep trace diagnostics outside positive coverage."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import control_values_examples as oracle

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/control-values-family-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
FALSE_FIELDS=('whole_workload_complete','independently_reviewed_statements',
              'benchmark_correspondence_certified','source_guards_adopted_as_proof_assumptions',
              'code_correspondence_performed','discarded_execution_observations_preserved',
              'arbitrary_dynamic_shape_behavior_proved')


def read(path,root=ROOT):return json.loads((root/path).read_text())
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    frozen=read(MANIFEST,root)
    for row in frozen['files']:assert digest(root/row['path'])==row['sha256'],row['path']
    assert digest(root/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['family']=='typed_pure_control_values_v1'
    assert len(frozen['profiles'])==frozen['profile_unit_count']==19
    labels={p['benchmark_id'] for p in frozen['profiles']}
    assert len(labels)==19 and sorted(labels)==frozen['candidate_benchmark_labels']
    assert sum(label.startswith('HandleSelect/') for label in labels)==14
    assert sum(label.startswith('HandleMap/') for label in labels)==4
    assert 'HandleConditional/predicate-convert' in labels
    assert {p['theorem'] for p in frozen['profiles']}<=set(frozen['certificates'])
    assert len(frozen['certificates'])==28 and len(frozen['counterexample_certificates'])==6
    assert not set(frozen['counterexample_certificates'])&set(frozen['candidate_benchmark_bindings'])
    assert {n for p in frozen['profiles'] for n in [p['theorem']]}==set(frozen['candidate_benchmark_bindings'])
    assert frozen['data_contract']=='arbitrary data types; no algebra, decidable equality or IEEE order instance'
    assert frozen['map_input_types']=='heterogeneous dependent input types at every finite arity'
    assert frozen['conditional_contract']=='exact selected branch and own argument; arbitrary result type, including state-to-observation computations'
    sheet=read(frozen['domain_worksheet'],root)
    assert sorted(r['benchmark_id'] for r in sheet['records'])==sorted(labels)
    for row in sheet['records']:
        assert row['whole_record_closed'] is False and row['candidate_label_correspondence_certified'] is False
        assert row['mathematical_premises'] and row['remaining_partitions']
        assert row['core_evidence']==[frozen['candidate_benchmark_bindings_inverse'][row['benchmark_id']]]
    return frozen


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:',stdout),stdout[-2000:]
    actual=stdout.strip().splitlines()
    expected=oracle.expected_lines()
    assert actual==expected,'actual graphs, operand selections, broadcasts, traces or stored bits differ from oracle'
    return dict(rows=len(actual),groups={prefix:sum(line.startswith(prefix+' ') for line in actual)
                for prefix in sorted({line.split()[0] for line in actual})},
                independent_dense_array_oracle=True,held_out_audit=False)


def validate_result(result,root=ROOT):
    frozen=check_inputs(root)
    assert result['status']=='kernel_complete_declared_mathematical_value_family'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(root/MANIFEST)
    assert result['profile_units']==frozen['profiles'] and result['profile_unit_count']==19
    assert result['covered_candidate_benchmark_labels']==frozen['candidate_benchmark_labels']
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert set(result['certificate_axioms'])==set(frozen['certificates'])
    for values in result['certificate_axioms'].values():assert set(values)<=ALLOWED
    assert result['controls']==validate_controls(result['control_stdout'])
    negative=result['invalid_profile_rejections']
    assert negative['returncode']!=0
    assert negative['diagnostic'].count('Tactic `decide` proved that the proposition')==4
    assert negative['diagnostic'].count('is false')==4
    assert negative['diagnostic'].count('error:')==4
    assert 'unexpected token' not in negative['diagnostic']
    assert 'Unknown identifier' not in negative['diagnostic']
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None
    assert result['code_correspondence_future_work'] is True


def main():
    frozen=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    positive=subprocess.run(['lake','env','lean','tests/fixtures/ControlValuesControls.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert positive.returncode==0,positive.stdout+positive.stderr
    controls=validate_controls(positive.stdout+positive.stderr)
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidControlValues.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    theory=read('reports/theory-progress.json')
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    axioms={name:values for name,values in theory['axiom_dependencies'].items() if '.ControlValues.' in name}
    result=dict(status='kernel_complete_declared_mathematical_value_family',manifest=MANIFEST,
        manifest_sha256=digest(ROOT/MANIFEST),profile_units=frozen['profiles'],profile_unit_count=19,
        covered_candidate_benchmark_labels=frozen['candidate_benchmark_labels'],
        certificate_axioms=axioms,counterexample_certificates=frozen['counterexample_certificates'],
        observations=frozen['observations'],controls=controls,control_stdout=positive.stdout+positive.stderr,
        invalid_profile_rejections=dict(returncode=negative.returncode,diagnostic=negative.stdout+negative.stderr),
        whole_benchmark_records_closed=0,mathematical_obligation_denominator=None,
        code_correspondence_future_work=True,**{field:False for field in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/control-values-family.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Control values: 19 complete declared profiles; 28 checked statements; '+str(controls['rows'])+
          ' oracle rows; four invalid profiles rejected. Full workload remains open.')


if __name__=='__main__':main()
