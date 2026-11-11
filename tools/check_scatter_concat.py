"""Check the actual leading-axis tensor-input Scatter bridge, retaining general layout gaps."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from scatter_concat_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/scatter-concat-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
TRUE_FIELDS=('actual_tensor_inputs_concatenated','leading_batch_axis_bridge_proved',
             'arbitrary_shared_trailing_batch_dimensions','duplicate_order_preserved',
             'elementwise_drop_preserved','whole_state_sequential_law_without_algebra',
             'assoc_comm_required_for_result_fusion','all_width_word_add_instantiation')
FALSE_FIELDS=('arbitrary_concat_axis_bridge_proved','all_scatter_dimension_numbers_supported',
              'floating_associativity_assumed','whole_window_drop_policy_proved',
              'full_family_complete','full_workload_complete','independently_reviewed_statements',
              'benchmark_correspondence_certified','external_ir_admission_proved',
              'code_correspondence_performed')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['candidate_benchmark_labels']==['HandleAdd/scatter-concat']
    assert frozen['geometry_contract']==('full-rank Scatter windows; common operand/window/index '
        'axes; concatenate actual indices and updates on the leading batch axis; arbitrary equal '
        'trailing batch dimensions; per-element drop; original batch/window order')
    assert frozen['algebra_contract']==('none for exact trace or sequential composition; '
        'assoc+comm for combining two results; all-width word Add requires distinct reducer roles')
    return frozen


def parse_controls(raw):
    groups=[]
    for prefix in ('CONCAT_COUNT','CONCAT_EVENT','CONCAT_VALUE'):
        rows=[]
        for line in raw.splitlines():
            if not line.startswith(prefix+' '):continue
            rows.append({key:json.loads(value) for key,value in
                         re.findall(r'(\w+)=(\[[\d, -]*\]|-?\d+)',line)})
        groups.append(rows)
    return tuple(groups)


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_checked_leading_batch_tensor_concat_bridge'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    axioms=result['certificate_axioms']
    assert result['checked_statement_count']==len(axioms)==9
    assert set(axioms)==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in axioms.values())
    oracle=expected()
    assert tuple(map(len,oracle))==(540,1890,810)
    for key,rows in zip(('profile_counts','event_controls','value_controls'),oracle):
        assert result[key]==rows,key
    for row in result['value_controls']:
        assert row['decimal']==row['nested']
        assert row['source']==row['target']
        assert row['word_source']==row['word_target']
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/ScatterConcatControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts,events,values=parse_controls(run.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.ScatterConcat.' in n}
    result=dict(status='kernel_checked_leading_batch_tensor_concat_bridge',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        checked_statement_count=len(axioms),profile_counts=counts,event_controls=events,
        value_controls=values,control_stdout=run.stdout,whole_benchmark_records_closed=0,
        mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/scatter-concat.json').write_text(json.dumps(result,indent=2)+'\n')
    print('9 tensor-input Concat/Scatter statements;540 profiles/1890 events/810 outputs agree; '
          'general dimension layouts and whole-record/campaign closure remain open.')


if __name__=='__main__':main()
