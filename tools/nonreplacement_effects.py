"""Source-inspected supplementary effects; all semantic/source acceptance pending."""
import collections
import hashlib
import json
from pathlib import Path

ROOT=Path(__file__).resolve().parents[1]

CALL_KINDS={
    'clear_sharding':'existing_instruction_metadata',
    'SetupDerivedInstruction':'derived_instruction_metadata_or_virtual_hook',
    'CopyOriginalValue':'existing_or_new_instruction_original_value_projection',
    'BuildAndAddRecoveryComputation':'module_recovery_table_and_instruction_metadata',
    'AddRecoveryComputation':'module_recovery_table_and_instruction_metadata',
    'AddEmbeddedComputation':'module_embedded_computation_construction',
    'GetOrCreateScalarAddComputation':'cached_module_embedded_computation_construction',
    'MarkAsChanged':'visitor_change_flag',
    'MarkAsUnchanged':'visitor_change_flag',
    'ResetVisitStates':'visitor_traversal_state',
    'Clear':'local_dimension_number_value',
    'clear_lhs_contracting_dimensions':'local_dimension_number_value',
    'clear_rhs_contracting_dimensions':'local_dimension_number_value',
    'clear_lhs_batch_dimensions':'local_dimension_number_value',
    'clear_rhs_batch_dimensions':'local_dimension_number_value',
    'clear_scatter_dims_to_operand_dims':'local_dimension_number_value',
    'SetToDefaultLayout':'local_shape_value',
}

# These bindings were inspected in context. A pointer/"mutable" spelling alone
# does not decide whether an existing graph node is mutated.
ASSIGNMENT_KINDS={
    1385:('new_instruction_layout','new_const constructed by CreateConstant immediately above'),
    5642:('existing_instruction_shape','barrier is the original HandleOptimizationBarrier input'),
    6316:('existing_instruction_shape','broadcast cast from original pad operand; one-user guard'),
    6317:('existing_instruction_dimensions','same original broadcast; dimensional projection'),
    6321:('new_instruction_padding_config','pad2 inserted by CloneWithNewShape immediately above'),
    6949:('existing_rng_shape','operand is original one-user Rng input to Reshape'),
    7702:('new_instruction_shape','broadcast returned by MakeBroadcastHlo immediately above'),
    7713:('new_instruction_shape','new_slice returned by MakeSliceHlo immediately above'),
    7776:('new_instruction_shape','new_slice returned by MakeSliceHlo inside DUS case'),
    7999:('new_instruction_layout','new_concat returned by MakeConcatHlo immediately above'),
    8634:('new_instruction_shape','concat returned by MakeConcatHlo immediately above'),
    10544:('local_dimension_number_value','new_dnums is a local DotDimensionNumbers'),
    10546:('local_dimension_number_value','same local new_dnums'),
    10560:('new_instruction_layout','new_dot returned by MakeDotHlo immediately above'),
    10580:('existing_rng_shape','operand is original one-user Rng input to Transpose'),
}


def source_contracts(root):
    # Contracts are inspected source behavior, not admitted Lean axioms.
    specs=[
        ('instruction-derived-metadata','sources/xla/xla/hlo/ir/hlo_instruction.cc',2568,2602,
         'writes derived node sharding by CompatibleKind, metadata, result accuracy, frontend attrs/statistics, removes compute-type attr, conditionally copies backend config'),
        ('visitor-derived-metadata-hook','sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.h',263,270,
         'virtual base hook delegates to old_inst->SetupDerivedInstruction(new_inst); derived backend overrides require separate contracts'),
        ('clear-sharding','sources/xla/xla/hlo/ir/hlo_instruction.h',1792,1792,
         'clears shared sharding pointer; an actual instruction metadata write'),
        ('tuple-original-value-projection','sources/xla/xla/hlo/ir/hlo_original_value_util.h',38,105,
         'vector negative entries pruned; creates new OriginalValue tree/call hierarchy and copies compatible mapped subtrees; may overwrite same instruction metadata'),
        ('module-recovery','sources/xla/xla/hlo/ir/hlo_module.cc',2092,2180,
         'checks structure; no-op for absent/synthetic old values; may set new metadata, pass through identity original arrays or insert placeholder/recovery modules; callback nullopt drops recovery'),
        ('embedded-computation','sources/xla/xla/hlo/ir/hlo_module.cc',262,267,
         'AddComputationInternal non-entry, uniquifying identifiers; not a tensor-node replacement'),
        ('cached-scalar-add','sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.h',424,442,
         'cache keyed by type; constructs scalar Add computation and adds to current module on cache miss; lifetime/current-module ownership needs review'),
        ('visitor-change-state','sources/xla/xla/hlo/ir/dfs_hlo_visitor_with_default.h',415,416,
         'MarkAsChanged/MarkAsUnchanged set visitor changed_ Boolean; no tensor graph mutation by themselves'),
    ]
    result=[]
    for name,path,start,end,behavior in specs:
        body='\n'.join((root/path).read_text().splitlines()[start-1:end])
        result.append(dict(id=name,path=path,line=start,end_line=end,source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                           source_behavior=behavior,status='source_inspected_pending_independent_semantic_review'))
    return result


def build(full,structural,mapping,root=ROOT):
    fs={f['id']:f for f in full['functions']}
    cases=collections.defaultdict(list)
    for b in mapping['bindings']:cases[b['owner']].append(b['case_id'])
    calls=[]
    for c in full['calls']:
        if c['call'] not in CALL_KINDS:continue
        owner=fs[c['owner_function_id']]['name'] if c['owner_function_id'] else None
        calls.append(dict(call_id=c['id'],line=c['line'],call=c['call'],source=c['source'],owner=owner,
                          classification=CALL_KINDS[c['call']],legacy_mutation_candidate=c['legacy_mutation_candidate'],
                          candidate_case_ids=cases[owner],
                          case_link_status='owner_only_candidates_need_exact_branch_and_caller_composition',
                          review_status='source_inspected_pending_independent_semantic_review',accepted_source_proof=None))
    assignments=[]
    for a in structural['assignment_expressions']:
        if not a['target'].lstrip().startswith('*') or 'mutable_' not in a['target']:continue
        kind,binding=ASSIGNMENT_KINDS[a['line']]
        assignments.append(dict(assignment_id=f"assignment-{a['byte_start']}-{a['byte_end']}",line=a['line'],source=a['source'],
                                target=a['target'],value=a['value'],classification=kind,binding_evidence=binding,
                                review_status='source_inspected_pending_independent_semantic_review',accepted_source_proof=None))
    result=dict(schema=1,status='partial_nonreplacement_effect_reconciliation',source_sha256=full['source_sha256'],
                denominator_frozen=False,calls=calls,assignments=assignments,contracts=source_contracts(root),
                limitations=['selected APIs and direct mutable pointer assignments only; all remaining calls/writes require review',
                             'owner-based case links are candidates, not exact branch/path correspondence',
                             'local value writes may feed later graph construction; not irrelevant merely because local',
                             'metadata/module/effect observation contracts and backend virtual overrides remain open',
                             'Rng shape changes need distribution/state refinement, not fixed-sample equality',
                             'no independent review or accepted source proof'])
    validate(result,full,structural,mapping,root)
    return result


def validate(result,full,structural,mapping,root=ROOT):
    if result['source_sha256']!=full['source_sha256'] or result['denominator_frozen']:
        raise ValueError('wrong effect source or premature census')
    expected=[c for c in full['calls'] if c['call'] in CALL_KINDS]
    if [c['call_id'] for c in result['calls']]!=[c['id'] for c in expected]:raise ValueError('supplementary call omitted')
    fs={f['id']:f for f in full['functions']}
    for c,e in zip(result['calls'],expected):
        if any(c[k]!=e[k] for k in ('line','call','source','legacy_mutation_candidate')):raise ValueError('wrong effect call identity')
        if c['classification']!=CALL_KINDS[e['call']]:raise ValueError('wrong source effect classification')
        owner=fs[e['owner_function_id']]['name'] if e['owner_function_id'] else None
        if c['owner']!=owner or c['candidate_case_ids']!=[b['case_id'] for b in mapping['bindings'] if b['owner']==owner]:raise ValueError('effect owner/case candidates omitted')
        if c['case_link_status']!='owner_only_candidates_need_exact_branch_and_caller_composition':raise ValueError('candidate case link promoted')
    expected_a=[a for a in structural['assignment_expressions'] if a['target'].lstrip().startswith('*') and 'mutable_' in a['target']]
    if [a['line'] for a in result['assignments']]!=[a['line'] for a in expected_a]:raise ValueError('direct pointer write omitted')
    for a,e in zip(result['assignments'],expected_a):
        if any(a[k]!=e[k] for k in ('line','source','target','value')):raise ValueError('wrong pointer write identity')
        if a['assignment_id']!=f"assignment-{e['byte_start']}-{e['byte_end']}":raise ValueError('wrong pointer write id')
        kind,binding=ASSIGNMENT_KINDS[e['line']]
        if (a['classification'],a['binding_evidence'])!=(kind,binding):raise ValueError('existing/new/local pointer classification changed')
    for e in result['calls']+result['assignments']:
        if e['review_status']!='source_inspected_pending_independent_semantic_review' or e['accepted_source_proof'] is not None:
            raise ValueError('partial effect promoted')
    if result['contracts']!=source_contracts(root):raise ValueError('source effect contract omitted or changed')


def main():
    load=lambda p:json.loads((ROOT/p).read_text())
    result=build(load('census/full-call-inventory.json'),load('census/normalized-structural-sites.json'),load('census/site-case-map.json'))
    (ROOT/'census/nonreplacement-effects.json').write_text(json.dumps(result,indent=2)+'\n')
    print(f"{len(result['calls'])} supplementary effect calls and {len(result['assignments'])} direct mutable pointer writes classified; independent/path review pending")


if __name__=='__main__':main()
