"""Bind inspected source schemas to precise call sites; leave all residuals explicit."""
import json
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def noncall_declarations(inventory, structural):
    if structural['source_sha256']!=inventory['source_sha256'] or structural['parse_has_errors']:
        raise ValueError('declaration exclusion requires matching error-free syntax view')
    excluded=[]
    for item in structural['lexical_only_sites']:
        if item['kind']!='replacement':continue
        if item['structural_classification']!='function_declarator_not_call' or not any(
            f['declarator_location']['line']<=item['line']<=f['declarator_location']['end_line']
            and item['call'] in f['declarator'] for f in structural['functions']):
            raise ValueError('unproved noncall declaration exclusion')
        original=next((s for s in inventory['sites'] if s['id']==item['id']),None)
        if original is None or any(item[k]!=v for k,v in original.items()):
            raise ValueError('wrong declaration identity')
        excluded.append(original)
    return excluded

def validate_replacement_coverage(batch, mapping, inventory):
    """Reconcile a declared lexical coverage scope, without asserting semantics."""
    owners=set(batch['lexical_replacement_coverage_owners'])
    if owners!={c['handler'] for c in batch['cases']}:
        raise ValueError('coverage owner omission')
    ids={c['id'] for c in batch['cases']}
    used=set()
    for binding in mapping['bindings']:
        if binding['case_id'] not in ids or binding['kind']!='replacement':continue
        used.add(binding['site_id'])
        used.update(s['site_id'] for s in binding.get('additional_sites',[]))
    expected={s['id'] for s in inventory['sites'] if s['kind']=='replacement' and s['owner'] in owners}
    if used!=expected:
        raise ValueError('lexical replacement coverage gap')

def validate_map(data, inventory, cases, structural):
    """Reject stale/fabricated bindings and omitted residual replacement sites."""
    if data['source_sha256'] != inventory['source_sha256'] or data['denominator_frozen']:
        raise ValueError('wrong source identity or prematurely frozen census')
    expected={c['id']:c for c in cases}
    bindings=data['bindings']
    if len(bindings)!=len(expected) or {r['case_id'] for r in bindings}!=set(expected):
        raise ValueError('missing or duplicate case bindings')
    sites={s['id']:s for s in inventory['sites'] if s['kind']=='replacement'}
    declarations=noncall_declarations(inventory,structural)
    if data['noncall_replacement_declarations']!=declarations:
        raise ValueError('declaration exclusion partition mismatch')
    excluded={s['id'] for s in declarations}
    definitions={d['name']:d for d in inventory['definitions']}
    used=set()
    for r in bindings:
        if r['owner']!=expected[r['case_id']]['handler']:
            raise ValueError('case owner mismatch')
        if r['kind']=='replacement':
            if r['site_id'] in excluded or any(s['site_id'] in excluded for s in r.get('additional_sites',[])):
                raise ValueError('function declaration cannot be a graph rewrite binding')
            case=expected[r['case_id']]
            if r.get('site_roles',[])!=case.get('site_roles',[]):
                raise ValueError('source construction/replacement role mismatch')
            if 'replacement_ordinals' in case:
                owned=[s for s in inventory['sites'] if s['kind']=='replacement' and s['owner']==r['owner']]
                required=[owned[i]['id'] for i in case['replacement_ordinals']]
                actual=[r['site_id']]+[s['site_id'] for s in r.get('additional_sites',[])]
                if actual!=required:
                    raise ValueError('source mutation sequence omission or order mismatch')
            s=sites[r['site_id']]
            if any(r[k]!=s[k] for k in ('owner','line','call')):
                raise ValueError('replacement site mismatch')
            used.add(r['site_id'])
            for extra in r.get('additional_sites',[]):
                s=sites[extra['site_id']]
                if any(extra[k]!=s[k] for k in ('owner','line','call')) or extra['owner']!=r['owner']:
                    raise ValueError('operation-sequence site mismatch')
                used.add(extra['site_id'])
        elif r['kind']=='delegation':
            if definitions[r['call']]['line']!=r['target_line']:
                raise ValueError('delegation target mismatch')
        else:
            raise ValueError('unknown binding kind')
    remaining=data['unmapped_replacement_sites']
    remaining_ids=[s['id'] for s in remaining]
    if len(remaining_ids)!=len(set(remaining_ids)) or set(remaining_ids)!=(set(sites)-used-excluded):
        raise ValueError('residual partition mismatch')
    if any(s!=sites[s['id']] for s in remaining):
        raise ValueError('modified residual site')


def main():
    index=json.loads((ROOT/'census/source-sites.json').read_text())
    structural=json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    simple=json.loads((ROOT/'census/simple-cases.json').read_text())['cases']
    shape_batch=json.loads((ROOT/'census/shape-cases.json').read_text())
    shape=shape_batch['cases']
    scalar_control=json.loads((ROOT/'census/scalar-control-cases.json').read_text())['cases']
    arithmetic=json.loads((ROOT/'census/arithmetic-cases.json').read_text())['cases']
    layout=json.loads((ROOT/'census/layout-cases.json').read_text())['cases']
    collective_rotation=json.loads((ROOT/'census/collective-rotation-cases.json').read_text())['cases']
    tensor_index=json.loads((ROOT/'census/tensor-index-cases.json').read_text())['cases']
    reduction=json.loads((ROOT/'census/reduction-cases.json').read_text())['cases']
    dot=json.loads((ROOT/'census/dot-cases.json').read_text())['cases']
    convolution=json.loads((ROOT/'census/convolution-cases.json').read_text())['cases']
    definitions={d['name']:d for d in index['definitions']}
    sites=index['sites']
    by_owner={}
    for s in sites:
        if s['kind']=='replacement': by_owner.setdefault(s['owner'],[]).append(s)
    # Source order independently selected from the inspected branch bodies.
    ordinals={}
    for owner in ('HandleAnd','HandleOr'):
        for name,ordinal in (('rhs-true',0),('lhs-true',1),('rhs-zero',2),('lhs-zero',3)):
            ordinals[owner+'/'+name]=ordinal
    ordinals.update({'HandleXor/equal-inputs':0,'HandleXor/rhs-zero':1,'HandleXor/lhs-zero':2,
        'HandleReal/complex-projection':0,'HandleReal/noncomplex':1,
        'HandleImag/complex-projection':0,'HandleImag/noncomplex':1})
    ordinals.update({'HandleSubtract/self':0,'HandleSubtract/zero':1,
        'HandleSubtract/constant':2,'HandleSubtract/broadcast-constant':2,
        'HandleSubtract/sub-sub-self':3,'HandleSubtract/sub-add-self-left':4,
        'HandleSubtract/sub-add-self-right':4,'HandleSubtract/add-sub-self-left':5,
        'HandleSubtract/add-sub-self-right':5})
    bindings=[]
    for case in simple+scalar_control+arithmetic+layout+collective_rotation+tensor_index+reduction+dot+convolution:
        if case.get('delegation_target'):
            target=case['delegation_target']
            bindings.append({'case_id':case['id'],'kind':'delegation','line':case['delegation_line'],
                             'call':target,'owner':case['handler'],'target_line':definitions[target]['line']})
            continue
        selected=case.get('replacement_ordinals',[ordinals.get(case['id'],0)])
        chosen=[by_owner[case['handler']][i] for i in selected]
        site=chosen[0]
        bindings.append({'case_id':case['id'],'kind':'replacement','site_id':site['id'],
                         'line':site['line'],'call':site['call'],'owner':case['handler'],
                         'additional_sites':[{'site_id':s['id'],'line':s['line'],'call':s['call'],'owner':s['owner']} for s in chosen[1:]],
                         'site_roles':case.get('site_roles',[]),
                         'site_order_interpretation':case.get('site_order_interpretation','source sequence; called-helper behavior still requires review'),
                         'unit_kind':case.get('unit_kind','source_case_pending_semantic_review'),
                         'acceptance_unit':case.get('acceptance_unit','branch/stage pending complete path composition' if case.get('unit_kind','').startswith('branch_or_rewrite_stage') else 'complete source case, including all sequential mutations')})
    delegations={'HandleReshape/transpose-chain-delegation':'TryRemovingBitcastOrReshapeTransposeChain',
                 'HandleReshape/transpose-hoist-delegation':'TryHoistTransposeOfReshape'}
    for case in shape:
        if case.get('delegation_target') or case['id'] in delegations:
            target=case.get('delegation_target') or delegations[case['id']]
            assert target in definitions
            bindings.append({'case_id':case['id'],'kind':'delegation','line':case['anchor_line'],
                             'call':target,'owner':case['handler'],'target_line':definitions[target]['line']})
            continue
        candidates=[s for s in by_owner[case['handler']] if s['line']>=case['anchor_line']]
        assert candidates,case['id']
        site=candidates[0]
        bindings.append({'case_id':case['id'],'kind':'replacement','site_id':site['id'],
                         'line':site['line'],'call':site['call'],'owner':case['handler']})
    ids=[r['case_id'] for r in bindings]
    assert len(ids)==len(set(ids))==len(simple)+len(shape)+len(scalar_control)+len(arithmetic)+len(layout)+len(collective_rotation)+len(tensor_index)+len(reduction)+len(dot)+len(convolution)
    used={r['site_id'] for r in bindings if r['kind']=='replacement'}
    used.update(s['site_id'] for r in bindings for s in r.get('additional_sites',[]))
    declarations=noncall_declarations(index,structural)
    excluded={s['id'] for s in declarations}
    residuals=[s for s in sites if s['kind']=='replacement' and s['id'] not in used|excluded]
    result={'schema':1,'status':'primary_agent_site_mapping_pending_independent_review',
            'source_sha256':index['source_sha256'],'denominator_frozen':False,
            'bindings':bindings,'unmapped_replacement_sites':residuals,'noncall_replacement_declarations':declarations,
            'limitations':['lexical site inventory is not exhaustive C++ semantics',
                          'mapping does not establish guard correctness or complete branch splitting',
                          'delegation and helper cases overlap; never sum as rewrite count',
                          'nonreplacement mutations require separate reconciliation']}
    validate_map(result,index,simple+shape+scalar_control+arithmetic+layout+collective_rotation+tensor_index+reduction+dot+convolution,structural)
    validate_replacement_coverage(shape_batch,result,index)
    (ROOT/'census/site-case-map.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f'{len(bindings)} case bindings; {len(used)} distinct replacement sites; {len(residuals)} replacement sites still unmapped; {len(declarations)} noncall declarations excluded')
    for r in bindings:
        print(f"{r['case_id']}: L{r['line']} {r['call']}")

if __name__=='__main__':main()
