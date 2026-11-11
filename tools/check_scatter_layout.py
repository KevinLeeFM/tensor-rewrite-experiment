"""Check raw update-layout and singleton-window derivations without claiming full Scatter coverage."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from scatter_layout_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/scatter-layout-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
TRUE_FIELDS=('actual_raw_update_tensor_read','arbitrary_batch_window_axis_interleaving',
             'inserted_singleton_window_axes_derived','coordinate_inverses_proved',
             'exact_ordered_trace_bridge','whole_state_preserved',
             'raw_storage_order_counterexample_checked','all_width_word_translation')
FALSE_FIELDS=('operand_index_batching_supported','implicit_index_vector_layout_supported',
              'arbitrary_relative_window_permutation_supported','all_scatter_dimension_numbers_supported',
              'whole_window_drop_policy_proved','raw_storage_order_equality_assumed',
              'floating_associativity_assumed','full_family_complete','full_workload_complete',
              'independently_reviewed_statements','external_ir_admission_proved',
              'benchmark_correspondence_certified','code_correspondence_performed')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['geometry_contract']==('arbitrary raw batch/window axis interleaving; '
        'singleton inserted operand-window dimensions; relative batch/window orders retained; '
        'shared injective signed index axes; per-element drop; batch-major/window-major order')
    assert frozen['algebra_contract']==('none for layout/trace/whole-state transport; '
        'homomorphism for scalar mapping; assoc for base translation; assoc+comm for nested '
        'result fusion; word Add requires distinct reducer roles')
    assert frozen['source_guards_adopted_as_proof_assumptions'] is False
    return frozen


def parse_controls(raw):
    groups=[]
    for prefix in ('LAYOUT_COUNT','LAYOUT_EVENT','LAYOUT_VALUE'):
        rows=[]
        for line in raw.splitlines():
            if line.startswith(prefix+' '):
                rows.append({key:json.loads(value) for key,value in
                    re.findall(r'(\w+)=(\[[\d, -]*\]|-?\d+)',line)})
        groups.append(rows)
    return tuple(groups)


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_checked_raw_update_layout_and_inserted_window_profile'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    axioms=result['certificate_axioms']
    assert result['checked_statement_count']==len(axioms)==16
    assert set(axioms)==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in axioms.values())
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert len(result['counterexample_certificates'])==1
    oracle=expected();assert tuple(map(len,oracle))==(197,201,830)
    for key,rows in zip(('profile_counts','event_controls','value_controls'),oracle):
        assert result[key]==rows,key
    assert sum(v['decimal']!=v['storage'] for v in result['value_controls'])==4
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ScatterLayoutControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts,events,values=parse_controls(run.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.ScatterLayout.' in n}
    result=dict(status='kernel_checked_raw_update_layout_and_inserted_window_profile',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        checked_statement_count=len(axioms),counterexample_certificates=frozen['counterexample_certificates'],
        profile_counts=counts,event_controls=events,value_controls=values,control_stdout=run.stdout,
        whole_benchmark_records_closed=0,mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/scatter-layout.json').write_text(json.dumps(result,indent=2)+'\n')
    print('16 raw-update/window-layout statements;197 profiles/201 events/830 outputs agree; '
          'storage order is distinct; general Scatter dimension layouts and full campaign remain open.')


if __name__=='__main__':main()
