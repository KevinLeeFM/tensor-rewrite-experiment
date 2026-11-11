"""Check an explicitly scoped ordered Scatter model; preserve tensor-input/dimension-number gaps."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from scatter_examples import expected

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/ordered-scatter-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
TRUE_FIELDS=('actual_window_event_generation','injective_signed_index_axes',
             'elementwise_out_of_bounds_drop_explicit','duplicate_order_preserved',
             'whole_coupled_state_preserved','derived_empty_vector_full_window_map',
             'associativity_required_for_base_translation','commutativity_required_for_trace_fusion',
             'actual_reducer_parameter_roles','all_width_word_instantiation')
FALSE_FIELDS=('all_scatter_dimension_numbers_supported','whole_window_drop_policy_proved',
              'tensor_input_concatenation_bridge_proved','transpose_dimension_bridge_proved',
              'floating_associativity_assumed','full_family_complete','full_workload_complete',
              'independently_reviewed_statements','benchmark_correspondence_certified',
              'code_correspondence_performed','external_ir_admission_proved')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    frozen=json.loads((ROOT/MANIFEST).read_text())
    for row in frozen['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    assert digest(ROOT/'lake-manifest.json')==frozen['lake_manifest_sha256']
    assert frozen['geometry_contract']=='full-rank windows; arbitrary batch rank; injective signed index axes; omitted axes start0; start+window coordinate checked per element without clamping; batch-major/window-major order'
    assert frozen['algebra_contract']=='actual whole-state reducer; no laws for ordered evaluation or empty/full-window Map; assoc for base translation and assoc+comm for two-trace fusion; word Add requires distinct parameter roles'
    domains=json.loads((ROOT/frozen['domain_worksheet']).read_text())
    for source in domains['retained_batches']:assert digest(ROOT/source['path'])==source['sha256']
    assert len(domains['records'])==6 and all(r['core_evidence'] and not r['whole_record_closed']
                                            for r in domains['records'])
    assert domains['source_guards_adopted_as_proof_assumptions'] is False
    catalog=json.loads((ROOT/frozen['worksheet_catalog']).read_text())
    prior=catalog['supersedes'];assert digest(ROOT/prior['path'])==prior['sha256']
    old=json.loads((ROOT/prior['path']).read_text())
    assert catalog['worksheets']==old['worksheets']+[dict(path=frozen['domain_worksheet'],
        sha256=digest(ROOT/frozen['domain_worksheet']),retained_record_count=6)]
    return frozen


def parse_controls(raw):
    groups=[]
    for prefix in ('SCATTER_COUNT','SCATTER_EVENT','SCATTER_VALUE','SCATTER_ROLE','SCATTER_FLOAT'):
        rows=[]
        for line in raw.splitlines():
            if not line.startswith(prefix+' '):continue
            row={}
            for key,value in re.findall(r'(\w+)=(\[[\d, -]*\]|true|false|-?\d+|[\w.]+)',line):
                row[key]=value.rsplit('.',1)[-1] if key in ('first','second') else json.loads(value)
            rows.append(row)
        groups.append(rows)
    return tuple(groups)


def validate_result(result):
    frozen=check_inputs()
    assert result['status']=='kernel_checked_ordered_scatter_profile_with_open_dimension_bridges'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(ROOT/MANIFEST)
    assert result['checked_statement_count']==len(result['certificate_axioms'])==36
    assert set(result['certificate_axioms'])==set(frozen['certificates'])
    assert all(set(a)<=ALLOWED for a in result['certificate_axioms'].values())
    assert result['counterexample_certificates']==frozen['counterexample_certificates']
    assert len(result['counterexample_certificates'])==4
    groups=expected()
    for key,rows in zip(('profile_counts','event_controls','value_controls','role_controls','float_controls'),groups):
        assert result[key]==rows,key
    assert tuple(map(len,groups))==(2709,3354,2968,11872,4)
    for key in TRUE_FIELDS:assert result[key] is True,key
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0
    assert result['mathematical_obligation_denominator'] is None


def main():
    frozen=check_inputs()
    run=subprocess.run(['lake','env','lean','tests/fixtures/OrderedScatterControls.lean'],
                       cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0 and 'warning:' not in run.stdout+run.stderr,run.stdout+run.stderr
    counts,events,values,roles,floats=parse_controls(run.stdout)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.OrderedScatter.' in n}
    domains=json.loads((ROOT/frozen['domain_worksheet']).read_text())
    assert {n for r in domains['records'] for n in r['core_evidence']}<=theory['axiom_dependencies'].keys()
    result=dict(status='kernel_checked_ordered_scatter_profile_with_open_dimension_bridges',
        manifest=MANIFEST,manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,
        checked_statement_count=len(axioms),counterexample_certificates=frozen['counterexample_certificates'],
        profile_counts=counts,event_controls=events,value_controls=values,role_controls=roles,
        float_controls=floats,control_stdout=run.stdout,whole_benchmark_records_closed=0,
        mathematical_obligation_denominator=None)
    result.update({key:True for key in TRUE_FIELDS});result.update({key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/ordered-scatter.json').write_text(json.dumps(result,indent=2)+'\n')
    print('36 ordered Scatter statements;2709 profiles/3354 events/2968 outputs,11872 role '
          'controls and4 binary32 controls agree. Dimension/Concat bridges and full campaign remain open.')


if __name__=='__main__':main()
