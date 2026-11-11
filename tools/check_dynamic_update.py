"""Replay bounded decoded-index update graphs and independent materialized-array controls."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import dynamic_update_examples as oracle

ROOT=Path(__file__).resolve().parents[1]
MANIFEST='census/dynamic-update-v1.json'
ALLOWED={'propext','Quot.sound','Classical.choice'}
FALSE_FIELDS=('all_machine_index_decoders_identified','floating_add_zero_laws_assumed',
              'general_strided_inside_slice_proved','full_family_complete','full_workload_complete',
              'independently_reviewed_statements','benchmark_correspondence_certified',
              'source_guards_adopted_as_proof_assumptions','code_correspondence_performed')


def digest(path):return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    manifest=json.loads((root/MANIFEST).read_text())
    assert manifest['model']=='decoded_bounded_dynamic_update_v1'
    assert len(manifest['certificates'])==41 and len(manifest['counterexample_certificates'])==3
    assert len(manifest['candidate_benchmark_labels'])==17
    assert manifest['index_contract']=='mathematical Int decoded starts, independently clamped per window and axis'
    assert manifest['value_contract']=='arbitrary data types for pure Slice/Update/Select; AddZeroClass only for Add graphs'
    assert manifest['static_slice_contract']=='derived legal unit-stride attributes; arbitrary positive strides not claimed'
    for row in manifest['files']:assert digest(root/row['path'])==row['sha256'],row['path']
    assert digest(root/'lake-manifest.json')==manifest['lake_manifest_sha256']
    sheet=json.loads((root/manifest['domain_worksheet']).read_text())
    assert sorted(row['benchmark_id'] for row in sheet['records'])==manifest['candidate_benchmark_labels']
    for row in sheet['records']:
        assert row['remaining_partitions'] and row['mathematical_premises']
        assert row['whole_record_closed'] is False and row['candidate_label_correspondence_certified'] is False
    return manifest


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:',stdout),stdout[-3000:]
    headers,locate,values,ieee=[],[],[],[]
    for line in stdout.splitlines():
        if line.startswith('DU_PROFILE '):
            match=re.fullmatch(r'DU_PROFILE domain=(\w+) profile=(\d+) outer=(\[.*?\]) inner=(\[.*?\]) raw=(\[.*?\]) start=(\[.*?\]) limits=(\[.*?\]) combined=(\[.*?\])',line)
            assert match,line
            headers.append((match[1],int(match[2]),*(tuple(json.loads(x)) for x in match.groups()[2:])))
        elif line.startswith('DU_LOCATE '):
            match=re.fullmatch(r'DU_LOCATE domain=(\w+) profile=(\d+) output=(\d+) decoded=(none|\[.*\])',line)
            assert match,line
            locate.append((match[1],int(match[2]),int(match[3]),None if match[4]=='none' else tuple(json.loads(match[4]))))
        elif line.startswith('DU_VALUE '):
            match=re.fullmatch(r'DU_VALUE domain=(\w+) profile=(\d+) kind=(\w+) output=(\d+) lhs=(-?\d+) rhs=(-?\d+)',line)
            assert match,line
            values.append((match[1],int(match[2]),match[3],int(match[4]),int(match[5]),int(match[6])))
        elif line.startswith('DU_IEEE '):ieee.append(line)
    expected=oracle.expected()
    assert headers==expected[0],'actual shape/start/static/combined attributes differ'
    assert locate==expected[1],'actual bounded membership/decoded coordinates differ'
    assert values==expected[2],'actual graphs differ from independent materialized arrays'
    assert ieee==['DU_IEEE lhs=0 rhs=2147483648']
    assert len(headers)==562 and len(locate)==1314 and len(values)==19096
    return dict(profiles=562,membership_rows=1314,graph_value_pairs=19096,
                graph_kinds=20,ieee_observation_rows=1)


def validate_result(result,root=ROOT):
    manifest=check_inputs(root)
    assert result['status']=='kernel_checked_decoded_bounded_dynamic_update_graphs'
    assert result['manifest']==MANIFEST and result['manifest_sha256']==digest(root/MANIFEST)
    assert set(result['certificate_axioms'])==set(manifest['certificates'])
    for axioms in result['certificate_axioms'].values():assert set(axioms)<=ALLOWED
    assert result['checked_statement_count']==41
    assert result['counterexample_certificates']==manifest['counterexample_certificates']
    assert result['candidate_benchmark_labels']==manifest['candidate_benchmark_labels']
    assert result['controls']==validate_controls(result['control_stdout'])
    rejection=result['binary32_add_zero_rejection']
    assert rejection['returncode']!=0 and re.search(r'error(?:\(|:)',rejection['diagnostic'])
    assert all(token in rejection['diagnostic'] for token in ('AddZeroClass','failed to synthesize'))
    for key in FALSE_FIELDS:assert result[key] is False,key
    assert result['whole_benchmark_records_closed']==0 and result['mathematical_obligation_denominator'] is None
    assert result['code_correspondence_future_work'] is True


def main():
    manifest=check_inputs()
    build=subprocess.run(['lake','build','TensorRewriteTheory'],cwd=ROOT,text=True,capture_output=True)
    assert build.returncode==0,build.stdout+build.stderr
    run=subprocess.run(['lake','env','lean','tests/fixtures/DynamicUpdateControls.lean'],cwd=ROOT,text=True,capture_output=True)
    assert run.returncode==0,run.stdout+run.stderr
    controls=validate_controls(run.stdout+run.stderr)
    invalid=subprocess.run(['lake','env','lean','tests/fixtures/InvalidDynamicUpdateFloatAdd.lean'],cwd=ROOT,text=True,capture_output=True)
    theory=json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:assert digest(ROOT/row['path'])==row['sha256'],row['path']
    axioms={n:a for n,a in theory['axiom_dependencies'].items() if '.DynamicUpdate.' in n}
    result=dict(status='kernel_checked_decoded_bounded_dynamic_update_graphs',manifest=MANIFEST,
        manifest_sha256=digest(ROOT/MANIFEST),certificate_axioms=axioms,checked_statement_count=len(axioms),
        counterexample_certificates=manifest['counterexample_certificates'],
        candidate_benchmark_labels=manifest['candidate_benchmark_labels'],controls=controls,
        control_stdout=run.stdout+run.stderr,binary32_add_zero_rejection=dict(returncode=invalid.returncode,
        diagnostic=invalid.stdout+invalid.stderr),whole_benchmark_records_closed=0,
        mathematical_obligation_denominator=None,code_correspondence_future_work=True,
        **{key:False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/dynamic-update.json').write_text(json.dumps(result,indent=2)+'\n')
    print('DynamicUpdate: 41 statements, 3 refutations, 562 profiles/1314 memberships/19096 graph pairs; '
          'decoded-index model only; full workload remains open.')


if __name__=='__main__':main()
