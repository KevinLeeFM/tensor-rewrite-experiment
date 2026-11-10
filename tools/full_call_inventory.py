"""All syntactic call expressions and candidate local dependencies, without typing."""
import collections
import hashlib
import json
from pathlib import Path
import re
from structural_inventory import extract
from cpp_syntax_view import syntax_view

ROOT=Path(__file__).resolve().parents[1]


def function_name(declarator):
    """Terminal declared identifier for ordinary functions in this source."""
    match=re.search(r'([A-Za-z_]\w*)\s*\(',declarator)
    return match[1] if match else None


def build(data, normalized, lexical, site_map):
    view, rewrites=syntax_view(data)
    full=extract(view,original=data,capture_all_calls=True)
    if full['parse_has_errors'] or full['source_sha256']!=normalized['source_sha256']:
        raise ValueError('full calls require the same error-free syntax view')
    functions=[]
    by_name=collections.defaultdict(list)
    for f in full['functions']:
        row=dict(f,id=f"function-{f['byte_start']}-{f['byte_end']}",name=function_name(f['declarator']))
        row['source_body_sha256']=hashlib.sha256(data[f['byte_start']:f['byte_end']]).hexdigest()
        functions.append(row)
        by_name[row['name']].append(row)
    legacy={(c['byte_start'],c['byte_end']):c for c in normalized['calls']}
    calls=[]
    for c in full['calls']:
        owner=[f for f in functions if f['byte_start']<=c['byte_start']<f['byte_end']]
        owner=min(owner,key=lambda f:f['byte_end']-f['byte_start']) if owner else None
        row=dict(c,id=f"call-{c['byte_start']}-{c['byte_end']}",
                 owner_function_id=owner['id'] if owner else None,
                 name_resolution='syntactic_terminal_identifier' if c['call'] else 'unresolved_indirect_callee',
                 local_definition_candidates=[f['id'] for f in by_name.get(c['call'],[])],
                 local_dispatch_status='candidate_by_name_only_not_resolved_overload_receiver_or_virtual_dispatch',
                 legacy_mutation_candidate=(c['byte_start'],c['byte_end']) in legacy,
                 overlapping_syntax_rewrites=[i for i,r in enumerate(rewrites) if r['byte_start']<c['byte_end'] and c['byte_start']<r['byte_end']],
                 review_status='pending_call_effect_and_dependency_review',accepted_source_proof=None)
        calls.append(row)
    handlers=[]
    for h in lexical['definitions']:
        if not h['name'].startswith('Handle'):continue
        fs=[f for f in functions if f['name']==h['name'] and f['line']<=h['line']<=f['end_line']]
        if len(fs)!=1:raise ValueError('handler/function source disagreement')
        f=fs[0]
        handlers.append(dict(handler=h['name'],function_id=f['id'],line=h['line'],end_line=h['end_line'],
                             all_call_ids=[c['id'] for c in calls if c['owner_function_id']==f['id']],
                             schema_ids=[b['case_id'] for b in site_map['bindings'] if b['owner']==h['name']],
                             review_status='pending_complete_handler_review'))
    result=dict(schema=1,status='all_syntactic_calls_not_semantic_effects_or_resolved_call_graph',
                source_sha256=full['source_sha256'],syntax_view_sha256=full['syntax_view_sha256'],
                denominator_frozen=False,functions=functions,calls=calls,handlers=handlers,
                limitations=['syntax-only macro view; no C++ typechecking or preprocessing',
                             'name matching is not call resolution; overload/virtual/receiver ambiguity stays explicit',
                             'call presence is not execution or a mutation; aliases and path composition pending',
                             'constructors, implicit calls and writes may require additional analysis',
                             'all handler schemas are provisional; no independent review or accepted source proofs'])
    validate(result,data,normalized,lexical,site_map)
    return result


def validate(result,data,normalized,lexical,site_map):
    if result['source_sha256']!=hashlib.sha256(data).hexdigest() or result['denominator_frozen']:
        raise ValueError('wrong full-call source or premature denominator')
    view,rewrites=syntax_view(data)
    expected=extract(view,original=data,capture_all_calls=True)
    if result['syntax_view_sha256']!=expected['syntax_view_sha256']:
        raise ValueError('wrong normalized syntax identity')
    original={(c['byte_start'],c['byte_end']):c for c in expected['calls']}
    calls=result['calls']
    coords=[(c['byte_start'],c['byte_end']) for c in calls]
    if len(coords)!=len(set(coords)) or set(coords)!=set(original):raise ValueError('full call omission or duplication')
    fs=result['functions']
    if len(fs)!=len(expected['functions']):raise ValueError('function omitted')
    for f,e in zip(fs,expected['functions']):
        if any(f[k]!=v for k,v in e.items()):raise ValueError('wrong function identity')
        if f['name']!=function_name(e['declarator']) or f['id']!=f"function-{f['byte_start']}-{f['byte_end']}":
            raise ValueError('wrong function name/id')
        if f['source_body_sha256']!=hashlib.sha256(data[f['byte_start']:f['byte_end']]).hexdigest():
            raise ValueError('stale function body')
    legacy={(c['byte_start'],c['byte_end']) for c in normalized['calls']}
    if not legacy<=set(coords):raise ValueError('legacy candidate dropped')
    for c in calls:
        e=original[(c['byte_start'],c['byte_end'])]
        if any(c[k]!=v for k,v in e.items()):raise ValueError('wrong call source/context')
        if c['id']!=f"call-{c['byte_start']}-{c['byte_end']}" or c['name_resolution']!=('syntactic_terminal_identifier' if c['call'] else 'unresolved_indirect_callee'):
            raise ValueError('wrong call identity or unresolved name promoted')
        if c['overlapping_syntax_rewrites']!=[i for i,r in enumerate(rewrites) if r['byte_start']<c['byte_end'] and c['byte_start']<r['byte_end']]:
            raise ValueError('macro provenance omitted')
        owners=[f for f in fs if f['byte_start']<=c['byte_start']<f['byte_end']]
        owner=min(owners,key=lambda f:f['byte_end']-f['byte_start']) if owners else None
        if c['owner_function_id']!=(owner['id'] if owner else None):raise ValueError('wrong call owner')
        if c['local_definition_candidates']!=[f['id'] for f in fs if f['name']==c['call']]:
            raise ValueError('local definition candidate omitted')
        if c['local_dispatch_status']!='candidate_by_name_only_not_resolved_overload_receiver_or_virtual_dispatch':
            raise ValueError('unresolved dispatch promoted')
        if c['legacy_mutation_candidate']!=((c['byte_start'],c['byte_end']) in legacy):raise ValueError('legacy coverage mismatch')
        if c['accepted_source_proof'] is not None or c['review_status']!='pending_call_effect_and_dependency_review':
            raise ValueError('unreviewed call promoted')
    handlers=result['handlers']
    hs=[d for d in lexical['definitions'] if d['name'].startswith('Handle')]
    if len(handlers)!=len(hs):raise ValueError('handler omitted')
    for h,e in zip(handlers,hs):
        if any(h[k]!=e[k] for k in ('line','end_line')) or h['handler']!=e['name']:raise ValueError('wrong handler identity')
        if h['schema_ids']!=[b['case_id'] for b in site_map['bindings'] if b['owner']==e['name']]:raise ValueError('handler schema omission')
        f=next(f for f in fs if f['id']==h['function_id'])
        if f['name']!=e['name']:raise ValueError('wrong handler function')
        if h['all_call_ids']!=[c['id'] for c in calls if c['owner_function_id']==f['id']]:raise ValueError('handler call omission')


def main():
    load=lambda p:json.loads((ROOT/p).read_text())
    data=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_bytes()
    result=build(data,load('census/normalized-structural-sites.json'),load('census/source-sites.json'),load('census/site-case-map.json'))
    (ROOT/'census/full-call-inventory.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f"{len(result['calls'])} syntactic calls across {len(result['functions'])} function definitions; {len(result['handlers'])} handlers reconciled; dispatch/effects unproved")


if __name__=='__main__':main()
