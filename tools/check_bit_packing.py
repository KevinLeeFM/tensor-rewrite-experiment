"""Replay exact stored-word repacking and partial dense Bitcast graphs; no source analysis."""
from collections import Counter
import hashlib
import json
from pathlib import Path
import re
import subprocess
import bit_packing_examples as oracle

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/bit-packing-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
FALSE_FIELDS=('full_workload_complete','full_bitcast_family_complete','independently_reviewed_statements',
    'benchmark_correspondence_certified','source_guards_adopted_as_proof_assumptions',
    'code_correspondence_performed','tiled_or_padded_storage_modeled','memory_alias_effects_modeled',
    'all_scalar_datatype_encodings_proved','numerical_conversion_is_bit_repacking',
    'empty_bit_count_determines_element_width','all_endianness_conventions_equated',
    'arbitrary_dynamic_shape_behavior_proved','byte_addressed_memory_model_proved',
    'last_contiguous_axis_replacement_complete','concat_repacking_complete')


def read(path,root=ROOT):return json.loads((root/path).read_text())
def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    frozen=read(MANIFEST,root)
    for row in frozen['files']:assert digest(root/row['path'])==row['sha256'],row['path']
    assert digest(root/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['model']=='bounded_stored_word_bit_packing_v1'
    assert len(set(frozen['certificates']))==len(frozen['certificates'])==31
    assert len(frozen['counterexample_certificates'])==4
    assert not set(frozen['counterexample_certificates'])&set(frozen['candidate_benchmark_bindings'])
    assert len(frozen['candidate_benchmark_labels'])==7
    assert frozen['candidate_benchmark_labels']==sorted({label for labels in
        frozen['candidate_benchmark_bindings'].values() for label in labels})
    assert frozen['storage_contract']=='actual bounded BitVec words; exact complete bit stream; explicit least-first or most-first order'
    assert frozen['layout_contract']=='arbitrary legal untiled dense minor-to-major permutations; no padding, tiles or aliases'
    assert frozen['shape_contract']=='all finite ranks and static extents; equal total bits independent of values; derived appended ratio axis'
    sheet=read(frozen['domain_worksheet'],root)
    assert sorted(r['benchmark_id'] for r in sheet['records'])==frozen['candidate_benchmark_labels']
    for row in sheet['records']:
        assert row['whole_record_closed'] is False
        assert row['candidate_label_correspondence_certified'] is False
        assert row['mathematical_premises'] and row['remaining_partitions']
        assert row['core_evidence'] and set(row['core_evidence'])<=set(frozen['certificates'])
    return frozen


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:',stdout),stdout[-2000:]
    lines=stdout.strip().splitlines()
    assert lines==oracle.expected_lines(),'stored-word values, shape inference, bit order or dense layout differ from oracle'
    groups=dict(Counter(line.split()[0] for line in lines))
    assert groups==dict(BP_BUFFER=1368,BP_SHAPE=384,BP_ORIGINAL=640,BP_PART=1120,
                        BP_LAYOUT=64,BP_LAYOUT_VALUE=512,BP_CELL=32,BP_FLOAT=7)
    return dict(rows=len(lines),groups=groups,independent_integer_stream_and_array_oracle=True,
                held_out_audit=False)


def validate_result(result,root=ROOT):
    frozen=check_inputs(root)
    assert result['status']=='kernel_checked_partial_stored_word_and_dense_bitcast_model'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(root/MANIFEST)
    assert set(result['certificate_axioms'])==set(frozen['certificates'])
    for values in result['certificate_axioms'].values():assert set(values)<=ALLOWED
    assert result['covered_candidate_benchmark_labels']==frozen['candidate_benchmark_labels']
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert result['controls']==validate_controls(result['control_stdout'])
    negative=result['invalid_profile_rejections']
    assert negative['returncode']!=0
    assert negative['diagnostic'].count('Tactic `decide` proved that the proposition')==4
    assert negative['diagnostic'].count('is false')==negative['diagnostic'].count('error:')==4
    for key in FALSE_FIELDS:assert result[key] is False,key
    for key in ('actual_word_stream_roundtrips_proved','arbitrary_width_repacking_composition_proved',
                'dense_layout_composition_proved','same_cell_bitcast_bridge_proved',
                'trailing_ratio_shape_derived','nonempty_width_inference_guard_required',
                'code_correspondence_future_work'):
        assert result[key] is True,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    positive=subprocess.run(['lake','env','lean','tests/fixtures/BitPackingControls.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    assert positive.returncode==0,positive.stdout+positive.stderr
    negative=subprocess.run(['lake','env','lean','tests/fixtures/InvalidBitPacking.lean'],
                            cwd=ROOT,text=True,capture_output=True)
    theory=read('reports/theory-progress.json')
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    result=dict(status='kernel_checked_partial_stored_word_and_dense_bitcast_model',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),
        certificate_axioms={name:theory['axiom_dependencies'][name] for name in frozen['certificates']},
        covered_candidate_benchmark_labels=frozen['candidate_benchmark_labels'],
        counterexample_certificates=frozen['counterexample_certificates'],
        controls=validate_controls(positive.stdout+positive.stderr),control_stdout=positive.stdout+positive.stderr,
        invalid_profile_rejections=dict(returncode=negative.returncode,diagnostic=negative.stdout+negative.stderr),
        actual_word_stream_roundtrips_proved=True,arbitrary_width_repacking_composition_proved=True,
        dense_layout_composition_proved=True,same_cell_bitcast_bridge_proved=True,
        trailing_ratio_shape_derived=True,nonempty_width_inference_guard_required=True,
        whole_benchmark_records_closed=0,mathematical_obligation_denominator=None,
        code_correspondence_future_work=True,**{key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/bit-packing.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Stored-word packing:31 statements;4127 oracle rows; four false goals rejected; seven partial records.')


if __name__=='__main__':main()
