"""Check derived paired operand/index batching while retaining remaining graph/observation gaps."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from scatter_batching_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/scatter-batching-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
TRUE_FIELDS=('actual_paired_batch_coordinates_derived','paired_extents_equal',
             'paired_operand_axes_inserted','paired_and_indexed_operand_axes_disjoint',
             'unsorted_pair_arrays_supported','partial_batch_pairing_supported',
             'actual_raw_index_batch_axis_derived','canonical_target_and_trace_bridge',
             'original_duplicate_and_drop_order_preserved','zero_pair_target_recovers_previous_model',
             'whole_state_preserved','all_width_word_translation','different_raw_layout_nested_fusion')
FALSE_FIELDS=('batch_coordinates_ignored','canonical_target_equality_assumed',
              'general_transpose_graph_bridge_proved','general_raw_concat_graph_bridge_proved',
              'relative_window_permutation_supported','whole_window_drop_policy_proved',
              'all_scatter_dimension_numbers_supported','floating_associativity_assumed',
              'full_family_complete','full_workload_complete','independently_reviewed_statements',
              'external_ir_admission_proved','benchmark_correspondence_certified',
              'code_correspondence_performed')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['geometry_contract']==('actual raw index/update tensors; injective signed '
        'operand/index batch-axis arrays with equal extents; paired operand axes inserted and '
        'disjoint from indexed axes; actual batch coordinates override paired positions; '
        'ordinary offsets plus windows elsewhere; batch/window order and per-element drop')
    assert frozen['canonical_contract']==('derive full identity operand-axis vector and every '
        'start from original indices or bounded batch coordinates; prove target, event and '
        'whole-state equivalence; no target equality or scalar algebra axiom')
    assert frozen['source_guards_adopted_as_proof_assumptions'] is False
    return frozen


def parse_controls(raw):
    return tuple([{key:json.loads(value) for key,value in
                   re.findall(r'(\w+)=(\[[\d, -]*\]|-?\d+)',line)}
                  for line in raw.splitlines() if line.startswith(prefix+' ')]
                 for prefix in ('BATCH_COUNT','BATCH_EVENT','BATCH_VALUE'))


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_checked_paired_batch_coordinates_and_raw_scatter_bridge'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    axioms=result['certificate_axioms']
    assert result['checked_statement_count']==len(axioms)==22
    assert set(axioms)==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in axioms.values())
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert len(result['counterexample_certificates'])==1
    oracle=expected();assert tuple(map(len,oracle))==(2035,2071,2071)
    for key,rows in zip(('profile_counts','event_controls','value_controls'),oracle):
        assert result[key]==rows,key
    assert sum(v['decimal']!=v['ignored'] for v in result['value_controls'])==664
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ScatterBatchingControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts,events,values=parse_controls(run.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.ScatterBatching.' in n}
    result=dict(status='kernel_checked_paired_batch_coordinates_and_raw_scatter_bridge',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        checked_statement_count=len(axioms),counterexample_certificates=frozen['counterexample_certificates'],
        profile_counts=counts,event_controls=events,value_controls=values,control_stdout=run.stdout,
        whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/scatter-batching.json').write_text(json.dumps(result,indent=2)+'\n')
    print('22 paired-batching statements;2035 profiles/2071 events/2071 outputs agree; '
          'ignoring batching changes664 outputs; remaining graph/observation/workload gaps stay open.')


if __name__=='__main__':main()
