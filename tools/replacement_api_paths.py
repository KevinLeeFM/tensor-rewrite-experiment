"""Static source/API closure for every provisional schema, not execution paths or proofs."""
import collections
import hashlib
import json
from pathlib import Path
from structural_inventory import Parser,Language,tree_sitter_cpp
from cpp_syntax_view import syntax_view

ROOT=Path(__file__).resolve().parents[1]
SOURCE='sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'
TYPES={
    ('ReplaceInstruction','absl::Status (HloInstruction *, HloInstruction *, bool)'):
        ('visitor-replace-status','DfsHloRewriteVisitor'),
    ('ReplaceInstruction','absl::StatusOr<bool> (HloInstruction *, HloInstruction *, bool, bool)'):
        ('visitor-replace-bool','DfsHloRewriteVisitor'),
    ('ReplaceWithNewInstruction','absl::Status (HloInstruction *, std::unique_ptr<HloInstruction>, bool, bool, bool, bool)'):
        ('visitor-replace-new','DfsHloRewriteVisitor'),
    ('ReplaceOperandWith','absl::Status (int64_t, HloInstruction *)'):
        ('instruction-replace-operand','HloInstruction'),
    ('ReplaceOperandWithDifferentShape','absl::Status (int64_t, HloInstruction *)'):
        ('instruction-replace-operand-different-shape','HloInstruction'),
    ('ReplaceAllUsesWith','absl::Status (HloInstruction *, absl::string_view)'):
        ('instruction-replace-all-uses','HloInstruction'),
    ('CloneWithReplacements','std::unique_ptr<HloComputation> (const absl::flat_hash_map<const HloInstruction *, std::unique_ptr<HloInstruction>> *, absl::Span<const HloInstruction *const>, HloCloneContext *, const std::string &, std::variant<const HloInstruction *, const absl::Span<HloInstruction *const>>)'):
        ('computation-clone-construction-boundary','HloComputation'),
    ('SwapConvolutionOperandsIfBeneficial','absl::StatusOr<bool> (HloConvolutionInstruction *, ConvOperandSwapper::ConvIsLowerableCallback)'):
        ('external-convolution-rewrite-boundary','SwapConvolutionOperandsIfBeneficial'),
    ('ReplaceUsesWith','absl::Status (absl::Span<HloInstruction *const>, HloInstruction *)'):
        ('instruction-replace-selected-uses','HloInstruction'),
}
SPECS=[
    ('fixedpoint-cap','transforms/simplifiers/algebraic_simplifier.h',45,50,
     'fixedpoint rerun cap is 50; reaching the cap logs a circular simplification warning'),
    ('fixedpoint-driver','transforms/simplifiers/algebraic_simplifier.cc',11315,11343,
     'reruns changed computations when enabled, increments run_count, stops at fixedpoint or cap; logs after cap'),
    ('fixedpoint-default','transforms/simplifiers/algebraic_simplifier_options.proto',110,112,
     'run_to_fixed_point proto option defaults to true'),
    ('visitor-new','ir/dfs_hlo_visitor_with_default.h',356,378,
     'forwards flags; sets changed true on OK status; default relay false/removal true/sharding false/frontend attrs true'),
    ('visitor-existing','ir/dfs_hlo_visitor_with_default.h',380,413,
     'relays controls and removes unused operands; changed OR returned bool; Status overload DCHECKs replacement'),
    ('compatible-existing','transforms/simplifiers/algebraic_simplifier.cc',861,881,
     'rejects old control predecessors and incompatible SameShape; preserves sharding/frontend attrs; StatusOr.value requires success'),
    ('compatible-span','transforms/simplifiers/algebraic_simplifier.cc',882,914,
     'rejects old control predecessors; singleton delegates; checks tuple sizes/shapes; nonempty CHECK; creates tuple; StatusOr.value requires success'),
    ('computation-new','ir/hlo_computation.cc',2039,2055,
     'adds new node before replacement; DCHECK returned changed; returns OK if replacement reports unchanged'),
    ('computation-existing','ir/hlo_computation.cc',2065,2164,
     'compatible shape then sharding gate; relays controls or skips controlled old node; copies metadata/original values/sharding; rewires uses; removes unused operands with ignore-controls equal relay flag'),
    ('remove-unused','ir/hlo_computation.cc',710,779,
     'retains side-effectful operands; may remove unused pure operands and drop their controls when ignore-controls true'),
    ('control-drop','ir/hlo_instruction.cc',3270,3282,
     'reconnects explicit control predecessor/successor pairs, then drops controls; data-use paths are not copied'),
    ('control-copy','ir/hlo_instruction.cc',3293,3307,
     'copies explicit old control predecessors/successors onto start/end'),
    ('operand-rewire','ir/hlo_instruction.cc',3658,3689,
     'checks shape/bounds as applicable; rewires operand/user lists; does not relay controls or delete old producer'),
    ('selected-use-rewire','ir/hlo_instruction.cc',3814,3839,
     'shape check then rewires requested users and root; no control relay or producer deletion'),
    ('clone-wrapper','ir/hlo_computation.cc',2341,2356,
     'creates a clone context if absent then delegates to CloneInContext; construction/helper semantics remain a boundary'),
    ('external-convolution-swap','transforms/simplifiers/conv_operand_swapper.cc',34,173,
     'external callback-sensitive rewrite with new convolution/reverse construction; relays controls/removes unused operands in computation replacement; full callback/graph contract pending'),
    ('all-use-rewire','ir/hlo_instruction.cc',3841,3901,
     'shape check then rewires users/root, retains replacement-as-user to avoid cycle, copies original value; no control relay or producer deletion'),
]


def contracts(root):
    records=[]
    for identity,suffix,start,end,behavior in SPECS:
        path='sources/xla/xla/hlo/'+suffix
        body='\n'.join((root/path).read_text().splitlines()[start-1:end])
        records.append(dict(id=identity,path=path,line=start,end_line=end,
            source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),source_behavior=behavior,
            status='source_inspected_pending_independent_semantic_review'))
    return records


def arguments(data):
    view,_=syntax_view(data)
    tree=Parser(Language(tree_sitter_cpp.language())).parse(view)
    if tree.root_node.has_error:raise ValueError('API arguments require error-free syntax view')
    result={};stack=[tree.root_node]
    while stack:
        node=stack.pop();stack.extend(reversed(node.named_children))
        if node.type!='call_expression':continue
        args=node.child_by_field_name('arguments')
        result[(node.start_byte,node.end_byte)]=[
            dict(source=data[c.start_byte:c.end_byte].decode(),byte_start=c.start_byte,byte_end=c.end_byte)
            for c in args.named_children if c.type!='comment']
    return result


def build(full,typed,mapping,root=ROOT):
    data=(root/SOURCE).read_bytes()
    if hashlib.sha256(data).hexdigest()!=full['source_sha256'] or typed['source_sha256']!=full['source_sha256']:
        raise ValueError('source identity mismatch')
    args=arguments(data)
    calls={c['id']:c for c in full['calls']}
    functions={f['id']:f for f in full['functions']}
    variants={r['ast_id']:r for r in typed['typed_variants']}
    resolved={r['source_call_id']:r for r in typed['source_calls']}
    by_owner=collections.defaultdict(list)
    for c in full['calls']:by_owner[c['owner_function_id']].append(c['id'])
    endpoints=[]
    for c in full['calls']:
        choices=[]
        for identity in resolved[c['id']]['ast_variant_ids']:
            callee=variants[identity].get('callee',{})
            key=(callee.get('name'),callee.get('type',{}).get('qualType'))
            if key not in TYPES:continue
            api,owner=TYPES[key]
            if owner not in (callee.get('mangled_name') or ''):
                raise ValueError('API type/name matched an unexpected class')
            choices.append((identity,api,callee))
        if not choices:continue
        if len({api for _,api,_ in choices})!=1:raise ValueError('ambiguous API category')
        api=choices[0][1];actual=args[(c['byte_start'],c['byte_end'])]
        relay='external_or_construction_boundary' if api.endswith('boundary') else 'no_control_relay_in_this_api'
        if api=='visitor-replace-new':
            relay='default_false' if len(actual)<4 else 'explicit_'+actual[3]['source']
            if relay not in ('default_false','explicit_true','explicit_false'):
                raise ValueError('nonliteral relay flag requires a reviewed profile')
        elif api.startswith('visitor-replace-'):relay='visitor_always_true'
        endpoints.append(dict(source_call_id=c['id'],line=c['line'],api=api,
            owner_function_id=c['owner_function_id'],source=c['source'],context=c['context'],
            endpoint_kind='external_or_construction_boundary' if api.endswith('boundary') else 'selected_mutation_API',
            selected_declarations=[dict(ast_variant_id=i,ast_decl_id=v['ast_decl_id'],
                mangled_name=v['mangled_name'],type=v['type']['qualType']) for i,_,v in choices],
            explicit_arguments=actual,control_relay=relay,accepted_source_proof=None,
            source_contract_status='API behavior only; caller guards, outcomes, aliases and observation refinement pending'))
    endpoint_map={r['source_call_id']:r for r in endpoints}
    summaries=[]
    for f in full['functions']:
        ids=by_owner[f['id']]
        summaries.append(dict(function_id=f['id'],name=f['name'],source_body_sha256=f['source_body_sha256'],
            selected_local_edges=[e for e in typed['local_call_edges'] if e['caller_function_id']==f['id']],
            endpoint_call_ids=[i for i in ids if i in endpoint_map],
            unmatched_call_ids=[i for i in ids if not resolved[i]['ast_variant_ids']],
            other_external_or_unresolved_call_ids=[i for i in ids if i not in endpoint_map and not resolved[i]['local_target_function_ids']]))
    records=[]
    for b in mapping['bindings']:
        entries=[]
        for anchor in [b]+b.get('additional_sites',[]):
            matches=[c['id'] for c in full['calls'] if c['line']==anchor['line'] and c['call']==anchor['call']
                     and functions.get(c['owner_function_id'],{}).get('name')==b['owner']]
            if len(matches)!=1:raise ValueError('schema anchor is not a unique call')
            entries.append(matches[0])
        queue=collections.deque((i,[i]) for i in entries);visited_functions=set();hits={};unresolved=[]
        while queue:
            identity,path=queue.popleft()
            if identity in endpoint_map:hits.setdefault(identity,path)
            targets=resolved[identity]['local_target_function_ids']
            if not targets and identity not in endpoint_map and identity in entries:unresolved.append(identity)
            for target in targets:
                if target in visited_functions:continue
                visited_functions.add(target)
                for child in by_owner[target]:queue.append((child,path+[child]))
        records.append(dict(source_case=b['case_id'],binding_kind=b['kind'],entry_call_ids=entries,
            reachable_function_ids=sorted(visited_functions),reachable_endpoint_ids=sorted(hits),
            endpoint_witnesses=[dict(endpoint_call_id=i,static_call_chain=hits[i]) for i in sorted(hits)],
            unresolved_entry_call_ids=sorted(set(unresolved)),
            path_scope='one static witness per reachable API site; helper alternatives overapproximated; feasibility, guard and alias composition unproved',
            accepted_source_proof=None))
    return dict(schema=1,status='whole_schema_static_replacement_API_closure_not_semantic_census_or_proof',
        source_sha256=full['source_sha256'],denominator_frozen=False,accepted_source_rewrites=0,
        native_status_diagnostic=dict(source_case='HandleAdd/constant-right',evidence='reports/replacement-status-replay-v1/result.json',scope='Bazel opt build; verified modules and HloEvaluator; bounded three single passes or one capped fixedpoint run',is_lean_refutation=False,unbounded_nontermination_claim=False,accepted_source_proof=None),
        api_contracts=contracts(root),api_endpoints=endpoints,function_summaries=summaries,source_cases=records,
        limitations=[f'all {len(records)} are provisional overlapping schemas, not semantic N',
            'static local declaration graph only; virtual dispatch, macros and template configurations remain open',
            'helper branch alternatives are included without proving any execution path',
            'all external/unmatched calls remain visible; this API catalog is not a closed effect model',
            'endpoint control defaults do not classify a source case as safe or buggy',
            'one witness per endpoint does not enumerate all paths or establish sequential mutation equivalence'])


def load_inputs(root=ROOT):
    return tuple(json.loads((root/('census/'+name+'.json')).read_text()) for name in
        ('full-call-inventory','typed-call-inventory','site-case-map'))


def validate(result,*inputs,root=ROOT):
    if result!=build(*inputs,root=root):raise ValueError('API path/case/default/contract omitted, retargeted or promoted')


if __name__=='__main__':
    result=build(*load_inputs())
    (ROOT/'census/replacement-api-paths.json').write_text(json.dumps(result,indent=2)+'\n')
    print('Static API paths:',len(result['source_cases']),'provisional schemas;',len(result['api_endpoints']),'typed endpoints; no semantic denominator or source acceptance')
