"""Link every extracted schema delegation to its compiler-selected local definition."""
import json
from pathlib import Path
from run_typed_ast import ROOT


def build(site_map,syntax,typed,proofs):
    functions={f['id']:f for f in syntax['functions']}
    resolved={r['source_call_id']:r for r in typed['source_calls']}
    records=[]
    for binding in site_map['bindings']:
        if binding['kind']!='delegation':continue
        calls=[c for c in syntax['calls'] if c['line']==binding['line'] and c['call']==binding['call']
               and functions[c['owner_function_id']]['name']==binding['owner']]
        if len(calls)!=1:raise ValueError('schema delegation does not identify one source call')
        call=calls[0];row=resolved[call['id']]
        if len(row['local_target_function_ids'])!=1:raise ValueError('delegation lacks one typed local target')
        target=functions[row['local_target_function_ids'][0]]
        if target['name']!=binding['call'] or not target['line']<=binding['target_line']<=target['end_line']:
            raise ValueError('typed target disagrees with the inspected helper definition')
        target_cases=sorted({b['case_id'] for b in site_map['bindings']
                             if target['line']<=b['line']<=target['end_line']})
        related=[rule for rule in proofs['rules'] if
                 set([rule.get('source_case')]+rule.get('additional_source_cases',[])) &
                 set([binding['case_id']]+target_cases)]
        records.append(dict(case_id=binding['case_id'],source_call_id=call['id'],line=binding['line'],
                            caller_function_id=call['owner_function_id'],selected_function_id=target['id'],
                            helper_source_body_sha256=target['source_body_sha256'],
                            ast_variant_ids=row['ast_variant_ids'],helper_source_case_ids=target_cases,
                            related_model_evidence=related,
                            recursive_static_dependency=call['owner_function_id']==target['id'],
                            accepted_source_proof=None,
                            scope='typed caller/helper dependency; guard, failure, alias and graph correspondence pending'))
    return dict(schema=1,status='all_extracted_delegations_typed_not_semantically_accepted',
                source_sha256=syntax['source_sha256'],denominator_frozen=False,accepted_source_rewrites=0,
                delegations=records)


def load_inputs(root=ROOT):
    load=lambda name:json.loads((root/name).read_text())
    return (load('census/site-case-map.json'),load('census/full-call-inventory.json'),
            load('census/typed-call-inventory.json'),load('census/pilot-value-proofs.json'))


def validate(result,*inputs):
    if result!=build(*inputs):raise ValueError('typed delegation omitted, retargeted or model evidence promoted')


if __name__=='__main__':
    result=build(*load_inputs())
    (ROOT/'census/typed-delegation-evidence.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Typed schema delegations:',len(result['delegations']),'; source acceptance remains zero')
