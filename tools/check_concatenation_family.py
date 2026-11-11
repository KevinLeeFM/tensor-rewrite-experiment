"""Replay the declared pure static Concat family; never perform code correspondence."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import check_concatenation as base
import concatenation_graph_examples as oracle

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/concatenation-values-family-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
DOMAINS={
    'unary':('concatenate_unary','one operand; every finite extent'),
    'filter-all-empty':('concatenate_all_empty_first_iff',
        'all actual operands empty; first replacement iff complete output shape equals first shape'),
    'filter-one-nonempty':('concatenate_only_nonempty','exactly one actual nonempty operand'),
    'filter-many-nonempty':('concatenate_filtered','actual filtered list nonempty; shape equality derived'),
    'flatten':('concatenate_flatten','arbitrary finite ordered operand groups'),
    'adjacent-slices':('slice_merge_run',
        'finite guarded merges; same input and legal other crops; shared positive stride; exact sampled adjacency'),
    'pad-low':('concatenate_pad_low','leading actual scalar Broadcast; same fill; nonnegative low padding'),
    'pad-high':('concatenate_pad_high','trailing actual scalar Broadcast; same fill; nonnegative high padding'),
    'repeat-unit-axis':('concatenate_repeated',
        'repeated identical input with selected extent one; ordinary delete-axis Reshape then signed-axis Broadcast')}
FALSE_FIELDS=('whole_workload_complete','independently_reviewed_statements',
    'benchmark_correspondence_certified','source_guards_adopted_as_proof_assumptions',
    'code_correspondence_performed','execution_effects_modeled','machine_attribute_overflow_modeled',
    'arbitrary_dynamic_shape_behavior_proved','unconditional_all_empty_first_shape_equality',
    'source_merge_loop_verified','blind_discovery_trial','library_ablation_performed')


def read(path,root=ROOT):return json.loads((root/path).read_text())
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    frozen=read(MANIFEST,root)
    for row in frozen['files']:assert digest(root/row['path'])==row['sha256'],row['path']
    assert digest(root/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['family']=='pure_static_concatenation_values_v1'
    assert frozen['profile_unit_count']==len(frozen['profiles'])==9
    expected={f'HandleConcatenate/{key}' for key in DOMAINS}
    assert set(frozen['candidate_benchmark_labels'])==expected
    retained=read('census/tensor-index-cases.json',root)
    assert expected=={r['id'] for r in retained['cases'] if r['id'].startswith('HandleConcatenate/')}
    for row in frozen['profiles']:
        key=row['id'].split('/')[1];name,domain=DOMAINS[key]
        assert row['benchmark_id']==row['id']
        assert row['theorem']=='TensorRewrite.Theory.Concatenation.'+name
        assert row['domain']==domain
        assert frozen['candidate_benchmark_bindings'][row['theorem']]==[row['id']]
    old=base.check_inputs(root)
    assert set(old['certificates'])<set(frozen['certificates'])
    assert len(frozen['certificates'])==93 and len(frozen['new_certificates'])==45
    assert set(frozen['new_certificates'])==set(frozen['certificates'])-set(old['certificates'])
    assert len(frozen['counterexample_certificates'])==4
    assert not set(frozen['counterexample_certificates'])&set(frozen['candidate_benchmark_bindings'])
    assert frozen['data_contract']=='all pure data types, arbitrary values; no numerical law or default data'
    assert frozen['observations']=='complete static tensor shapes and every logical data value'
    sheet=read(frozen['domain_worksheet'],root)
    assert {r['benchmark_id'] for r in sheet['records']}==expected
    for row in sheet['records']:
        assert row['whole_record_closed'] is False
        assert row['candidate_label_correspondence_certified'] is False
        assert row['core_evidence']==[next(p['theorem'] for p in frozen['profiles'] if p['id']==row['benchmark_id'])]
        assert row['mathematical_premises'] and row['remaining_partitions']
    return frozen


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:',stdout),stdout[-2000:]
    actual=stdout.strip().splitlines()
    assert actual==oracle.expected_lines(),'Slice/Pad/ordinary Reshape/Broadcast differs from independent arrays'
    groups=dict(Counter(line.split()[0] for line in actual))
    assert groups==dict(AG_PROFILE=252,AG_VALUE=7904,PG_PROFILE=648,PG_VALUE=2016,
                        RG_PROFILE=144,RG_VALUE=574,CG_FLOAT=6)
    return dict(rows=len(actual),groups=groups,independent_materialized_array_oracle=True,
                held_out_audit=False)


def validate_result(result,root=ROOT):
    frozen=check_inputs(root)
    assert result['status']=='kernel_complete_declared_mathematical_value_family'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(root/MANIFEST)
    assert result['profile_units']==frozen['profiles'] and result['profile_unit_count']==9
    assert result['covered_candidate_benchmark_labels']==frozen['candidate_benchmark_labels']
    assert set(result['certificate_axioms'])==set(frozen['certificates'])
    for values in result['certificate_axioms'].values():assert set(values)<=ALLOWED
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert result['controls']==validate_controls(result['control_stdout'])
    negative=result['invalid_profile_rejections']
    assert negative['returncode']!=0
    assert negative['diagnostic'].count('Tactic `decide` proved that the proposition')==4
    assert negative['diagnostic'].count('is false')==negative['diagnostic'].count('error:')==4
    assert result['base_replay']=='reports/concatenation-base-replay-v2.json'
    assert result['base_replay_sha256']==digest(root/result['base_replay'])
    base.validate_result(read(result['base_replay'],root),root)
    for key in FALSE_FIELDS:assert result[key] is False,key
    for key in ('arbitrary_positive_slice_stride_proved','non_axis_crop_stride_proved',
                'finite_guarded_merge_runs_proved','actual_boundary_pad_graphs_proved',
                'ordinary_reshape_broadcast_proved','code_correspondence_future_work'):
        assert result[key] is True,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    positive=subprocess.run(['lake','env','lean','tests/fixtures/ConcatenationGraphControls.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert positive.returncode==0,positive.stdout+positive.stderr
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidConcatenationGraphs.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    theory=read('reports/theory-progress.json')
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    result=dict(status='kernel_complete_declared_mathematical_value_family',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),
        certificate_axioms={n:theory['axiom_dependencies'][n] for n in frozen['certificates']},
        profile_units=frozen['profiles'],profile_unit_count=9,observations=frozen['observations'],
        covered_candidate_benchmark_labels=frozen['candidate_benchmark_labels'],
        counterexample_certificates=frozen['counterexample_certificates'],
        controls=validate_controls(positive.stdout+positive.stderr),control_stdout=positive.stdout+positive.stderr,
        invalid_profile_rejections=dict(returncode=negative.returncode,diagnostic=negative.stdout+negative.stderr),
        base_replay='reports/concatenation-base-replay-v2.json',
        base_replay_sha256=digest(ROOT/'reports/concatenation-base-replay-v2.json'),
        arbitrary_positive_slice_stride_proved=True,non_axis_crop_stride_proved=True,
        finite_guarded_merge_runs_proved=True,actual_boundary_pad_graphs_proved=True,
        ordinary_reshape_broadcast_proved=True,whole_benchmark_records_closed=0,
        mathematical_obligation_denominator=None,code_correspondence_future_work=True,
        **{key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/concatenation-values-family.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Concat family:9 declared pure static profiles;45 new statements;1044 profiles/11544 rows; four false goals rejected.')


if __name__=='__main__':main()
