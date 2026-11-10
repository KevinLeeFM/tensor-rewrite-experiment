"""Index independently inspected local source paths without freezing semantic obligations."""
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]


def load(root,path):return json.loads((root/path).read_text())


def validate_artifact(artifact,cases,root=ROOT):
    scope=artifact['scope']
    assert not scope['denominator_frozen'] and scope['accepted_source_rewrites']==0
    assert len(artifact['cases'])==scope['exact_id_count']
    proposed=artifact.get('proposed_entries',[])
    assert len(proposed)==scope.get('proposed_added_entry_count',0)
    rows=artifact['cases']+proposed
    assert len({r['id'] for r in rows})==len(rows)
    functions={f['id']:f for f in load(root,'census/full-call-inventory.json')['functions']}
    source=(root/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()
    spans=artifact['source_spans']
    for key,span in spans.items():
        text=''.join((root/span['path']).read_text().splitlines(keepends=True)[span['start_line']-1:span['end_line']])
        assert text==span['source_text'],key
        assert hashlib.sha256(text.encode()).hexdigest()==span['sha256'],key
    def validate_span_refs(value):
        if isinstance(value,dict):
            for key,item in value.items():
                if key in ('source_span','body_span','entry_capture_span','source_spans'):
                    if isinstance(item,str):assert item in spans,item
                    elif isinstance(item,list):
                        for reference in item:
                            if isinstance(reference,str):assert reference in spans,reference
                validate_span_refs(item)
        elif isinstance(value,list):
            for item in value:validate_span_refs(item)
    for key,value in artifact.items():
        if key!='source_spans':validate_span_refs(value)
    for row in rows:
        case=cases[row['id']]
        if 'source_function_id' in row:
            function=functions[row['source_function_id']]
            interval=[function['byte_start'],function['byte_end']]
            assert row['source_function_byte_interval']==interval
            assert function['name']==case['handler']
            assert function['line']<=case['line']<=function['declarator_location']['end_line']
            assert function['end_line']==case['end_line']
            assert row['source_body_sha256']==function['source_body_sha256']
            assert hashlib.sha256(source[interval[0]:interval[1]]).hexdigest()==row['source_body_sha256']
        if 'source_body_sha256' in case:
            if row['source_body_sha256']!=case['source_body_sha256']:
                # Older line-based batches omit a separately wrapped return type;
                # newer reviews hash the complete parser byte interval. Check both.
                assert 'source_function_id' in row
                lines=source.decode().splitlines()[case['line']-1:case['end_line']]
                assert hashlib.sha256('\n'.join(lines).encode()).hexdigest()==case['source_body_sha256']
        else:
            assert 'source_function_id' in row
        if 'replacement_site_id' in case:
            assert row['provisional_replacement_site_id']==case['replacement_site_id']
            assert row['provisional_replacement_line']==case['replacement_line']
        else:
            assert row['frozen_binding_kind']=='delegation'
            assert row['provisional_replacement_site_id'] is None and row['provisional_replacement_line'] is None
            assert row['delegation_line']==case['delegation_line']
            assert row['delegation_target']==case['delegation_target']
        assert row['stage_ref'] in artifact['stages']
        assert all(k in artifact['stages'] for k in row['earlier_return_constraints']['ordered_prior_stage_refs'])
        assert all(k in artifact['shared_contracts'] for k in row['selected_api_contract_refs'])
        assert row['acceptance'].replace('; ', ';')=='none;no source/proof acceptance or denominator freeze'
        assert row['ordered_actions'] and row['actual_guard'] and row['terminal_behavior']
        for predicate in row['actual_guard']:
            if isinstance(predicate.get('source_span'),str):assert predicate['source_span'] in spans


def build(root=ROOT):
    bindings=load(root,'census/site-case-map.json')['bindings']
    expected={b['case_id'] for b in bindings}
    cases={}
    for path in (root/'census').glob('*cases.json'):
        for case in json.loads(path.read_text()).get('cases',[]):
            if case['id'] not in expected:continue
            assert case['id'] not in cases,'duplicate current source-case identity'
            cases[case['id']]=case
    assert set(cases)==expected
    for binding in bindings:
        case=cases[binding['case_id']]
        if binding['kind']=='replacement':
            if 'replacement_site_id' in case:
                assert case['replacement_site_id']==binding['site_id']
                assert case['replacement_line']==binding['line']
            case=dict(case,replacement_site_id=binding['site_id'],replacement_line=binding['line'])
        else:
            assert binding['kind']=='delegation'
            case=dict(case,delegation_line=binding['line'],delegation_target=binding['call'])
        cases[binding['case_id']]=case
    resolution=load(root,'reviews/census-pilot-v1-resolution.json')
    records=[];seen=set();inputs=[]
    for review in resolution.get('source_normalization_reviews',[]):
        path=Path(review['path'])
        assert hashlib.sha256((root/path).read_bytes()).hexdigest()==review['sha256']
        assert hashlib.sha256((root/review['companion']).read_bytes()).hexdigest()==review['companion_sha256']
        artifact=load(root,path);validate_artifact(artifact,cases,root)
        assert review['exact_variant_count']==artifact['scope']['exact_id_count']
        assert artifact['input']['xla_commit']==load(root,'sources/manifest.json')['xla_commit']
        inputs.append(review)
        for row in artifact['cases']+artifact.get('proposed_entries',[]):
            assert row['id'] not in seen,'conflicting independent normalizations need explicit reconciliation'
            seen.add(row['id'])
            complete=not row['remaining_local_source_work']
            records.append(dict(source_case=row['id'],handler=row['handler'],registry_role=row['registry_role'],
                alias_of=row.get('alias_of'),source_enumeration_notes=row.get('source_enumeration_notes',[]),
                source_local_reachability=row.get('source_local_reachability'),
                shared_action_group=row['shared_action_group'],review_path=str(path),review_sha256=review['sha256'],
                stage_ref=row['stage_ref'],local_source_work_complete=complete,
                status='independently_inspected_local_paths_under_declared_interfaces' if complete else 'explicit_local_source_work_remaining',
                accepted_source_proof=None))
    complete={r['source_case'] for r in records if r['local_source_work_complete']}
    return dict(schema=1,status='partial_independent_local_source_normalization_not_canonical_N_or_proof_acceptance',
                source_commit=load(root,'sources/manifest.json')['xla_commit'],denominator_frozen=False,
                semantic_denominator=None,family_denominator=None,accepted_source_rewrites=0,
                provisional_schema_count=len(expected),independently_locally_normalized_record_count=len(complete),
                not_yet_locally_normalized_case_ids=sorted(expected-complete),records=records,review_inputs=inputs,
                boundary='exact source snippets and reviewed local paths; symbolic helper/constructor boundaries explicit; canonical alias quotient, caller/global/effect composition, models and proofs separate')


def main():
    result=build()
    (ROOT/'census/source-normalization-registry.json').write_text(json.dumps(result,indent=2)+'\n')
    print(str(result['independently_locally_normalized_record_count'])+' independently normalized local source records; N/F and proof acceptance remain open.')


if __name__=='__main__':main()
