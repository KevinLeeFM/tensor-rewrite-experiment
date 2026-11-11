"""Replay arbitrary-axis concatenation, guarded emptiness and actual selected-group Slice graphs."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import concatenation_examples as oracle

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/concatenation-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
FALSE_FIELDS=('full_workload_complete','full_concatenation_family_complete',
              'independently_reviewed_statements','benchmark_correspondence_certified',
              'source_guards_adopted_as_proof_assumptions','code_correspondence_performed',
              'unconditional_actual_empty_filter_preserves_shape',
              'all_empty_alone_implies_first_shape_equality','adjacent_slice_merge_proved',
              'concatenation_pad_graphs_proved','unit_axis_reshape_broadcast_graph_proved',
              'non_axis_slice_crops_proved','arbitrary_dynamic_shape_behavior_proved',
              'execution_effects_modeled','machine_attribute_overflow_modeled')


def read(path,root=ROOT):return json.loads((root/path).read_text())
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    frozen=read(MANIFEST,root)
    for row in frozen['files']:assert digest(root/row['path'])==row['sha256'],row['path']
    assert digest(root/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['model']=='arbitrary_axis_nary_concatenation_v1'
    assert len(frozen['certificates'])==48 and len(frozen['counterexample_certificates'])==4
    assert len(frozen['candidate_benchmark_labels'])==8
    assert frozen['candidate_benchmark_labels']==sorted(set(
        label for labels in frozen['candidate_benchmark_bindings'].values() for label in labels))
    assert not set(frozen['counterexample_certificates'])&set(frozen['candidate_benchmark_bindings'])
    assert frozen['data_contract']=='arbitrary pure data types; no algebra, equality or default-value instance'
    assert frozen['shape_contract']=='all finite ranks with a legal selected axis; arbitrary static extents including every empty-axis case'
    assert frozen['filter_contract']=='actual-empty filtering derives shape equality from a nonempty kept list; zero-axis filtering is unconditional'
    assert frozen['all_empty_contract']=='first-operand shape-and-value equivalence iff full shapes agree; selected-extent equality is necessary and sufficient'
    assert frozen['slice_contract']=='legal unit strides on the selected axis, with all other dimensions retained; derived prefix and output interval'
    sheet=read(frozen['domain_worksheet'],root)
    assert sorted(r['benchmark_id'] for r in sheet['records'])==frozen['candidate_benchmark_labels']
    for row in sheet['records']:
        assert row['whole_record_closed'] is False and row['candidate_label_correspondence_certified'] is False
        assert row['remaining_partitions'] and row['mathematical_premises']
        assert row['core_evidence'] and set(row['core_evidence'])<=set(frozen['certificates'])
    return frozen


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:',stdout),stdout[:2000]
    lines=stdout.strip().splitlines();expected=oracle.expected_lines()
    assert lines==expected,'actual shapes, filtering, segment values, Slice offsets or stored bits differ from oracle'
    groups=dict(Counter(line.split()[0] for line in lines))
    assert groups==dict(CAT_PROFILE=1512,CAT_VALUE=5328,CAT_SLICE=4896,CAT_FLOAT=6)
    profiles=[line for line in lines if line.startswith('CAT_PROFILE ')]
    assert len(set(profiles))==1512
    return dict(rows=len(lines),groups=groups,independent_materialized_array_oracle=True,held_out_audit=False)


def validate_result(result,root=ROOT):
    frozen=check_inputs(root)
    assert result['status']=='kernel_checked_partial_arbitrary_axis_concatenation_and_slice_model'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(root/MANIFEST)
    assert result['covered_candidate_benchmark_labels']==frozen['candidate_benchmark_labels']
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert set(result['certificate_axioms'])==set(frozen['certificates'])
    for values in result['certificate_axioms'].values():assert set(values)<=ALLOWED
    assert result['controls']==validate_controls(result['control_stdout'])
    negative=result['invalid_profile_rejections']
    assert negative['returncode']!=0
    assert negative['diagnostic'].count('Tactic `decide` proved that the proposition')==4
    assert negative['diagnostic'].count('is false')==4 and negative['diagnostic'].count('error:')==4
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['all_empty_first_shape_iff_proved'] is True
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None
    assert result['code_correspondence_future_work'] is True


def main():
    frozen=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    positive=subprocess.run(['lake','env','lean','tests/fixtures/ConcatenationControls.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert positive.returncode==0,positive.stdout+positive.stderr
    controls=validate_controls(positive.stdout+positive.stderr)
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidConcatenation.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    theory=read('reports/theory-progress.json')
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    axioms={name:values for name,values in theory['axiom_dependencies'].items() if '.Concatenation.' in name}
    result=dict(status='kernel_checked_partial_arbitrary_axis_concatenation_and_slice_model',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        covered_candidate_benchmark_labels=frozen['candidate_benchmark_labels'],
        counterexample_certificates=frozen['counterexample_certificates'],controls=controls,
        control_stdout=positive.stdout+positive.stderr,
        invalid_profile_rejections=dict(returncode=negative.returncode,diagnostic=negative.stdout+negative.stderr),
        all_empty_first_shape_iff_proved=True,whole_benchmark_records_closed=0,
        mathematical_obligation_denominator=None,code_correspondence_future_work=True,
        **{key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/concatenation.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Concatenation:48 statements;1512 control profiles/'+str(controls['rows'])+
          ' oracle rows; four invalid profiles rejected. Eight partial records; full workload remains open.')


if __name__=='__main__':main()
