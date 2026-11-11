"""Check explicit/implicit raw index-tensor readers and a derived raw-input Scatter profile."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from scatter_indices_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/scatter-indices-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
PREFIXES=('READER_COUNT','READER_RAW','READER_VALUE','READER_TARGET',
          'INDEX_COUNT','INDEX_EVENT','INDEX_VALUE')
GROUPS=('reader_profile_counts','raw_controls','read_controls','relayout_controls',
        'scatter_profile_counts','event_controls','value_controls')
COUNTS=(162,230,230,230,305,381,1115)
TRUE_FIELDS=('raw_index_reading_derived','explicit_vector_axis_all_positions',
             'implicit_vector_exactly_one_component','empty_vector_distinct_from_empty_batch',
             'reader_pack_inverse_proved','vector_axis_relayout_proved',
             'actual_raw_tensor_scatter_bridge','all_width_word_translation',
             'scalar_decode_transport_without_decoder_equivalence')
FALSE_FIELDS=('all_scatter_dimension_numbers_supported','operand_index_batching_supported',
              'general_transpose_graph_bridge_proved','relative_batch_permutation_supported',
              'relative_window_permutation_supported','whole_window_drop_policy_proved',
              'raw_index_emptiness_implies_no_events','signed_unsigned_decoders_identified',
              'floating_associativity_assumed','full_family_complete','full_workload_complete',
              'independently_reviewed_statements','external_ir_admission_proved',
              'benchmark_correspondence_certified','code_correspondence_performed')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['reader_contract']==('one explicit vector axis at any raw position, or an '
        'implicit vector of exactly one component; relative batch order retained; actual '
        'bounded coordinate insertion/projection and lossless packing/relayout')
    assert frozen['scatter_contract']==('actual raw index/update tensors; previous compact-window '
        'and singleton insertion profile; injective signed operand-axis map; batch/window order '
        'and per-element drop; no reducer algebra for input/relayout bridges')
    assert frozen['source_guards_adopted_as_proof_assumptions'] is False
    return frozen


def parse_controls(raw):
    return tuple([{key:json.loads(value) for key,value in
                   re.findall(r'(\w+)=(\[[\d, -]*\]|-?\d+)',line)}
                  for line in raw.splitlines() if line.startswith(prefix+' ')] for prefix in PREFIXES)


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_checked_explicit_implicit_raw_indices_with_open_general_dimensions'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    axioms=result['certificate_axioms']
    assert result['checked_statement_count']==len(axioms)==20
    assert set(axioms)==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in axioms.values())
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert len(result['counterexample_certificates'])==1
    oracle=expected();assert tuple(map(len,oracle))==COUNTS
    for key,rows in zip(GROUPS,oracle):assert result[key]==rows,key
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ScatterIndicesControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    controls=parse_controls(run.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items()
            if '.IndexVector.' in n or '.ScatterIndices.' in n}
    result=dict(status='kernel_checked_explicit_implicit_raw_indices_with_open_general_dimensions',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        checked_statement_count=len(axioms),counterexample_certificates=frozen['counterexample_certificates'],
        control_stdout=run.stdout,whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    result.update(dict(zip(GROUPS,controls)))
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/scatter-indices.json').write_text(json.dumps(result,indent=2)+'\n')
    print('20 raw-index/Scatter statements;162 reader profiles and305 Scatter profiles agree; '
          'explicit zero vectors differ from implicit singleton vectors and empty batches; '
          'general dimension/workload closure remains open.')


if __name__=='__main__':main()
