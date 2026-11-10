"""Collective/remainder/rotation schemas, distinguishing factories from rewrites."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers

ROOT = Path(__file__).resolve().parents[1]


def validate_site_roles(batch, structural):
    calls={(c['line'],c['call']):c for c in structural['calls']}
    for case in batch['cases']:
        if case.get('site_order_interpretation')!='source_coordinates_with_nested_factory_argument':continue
        items=[case]+case['additional_replacement_sites']
        roles=case['site_roles']
        if [r['role'] for r in roles]!=['graph_replacement','replacement_argument_construction']:
            raise ValueError('factory misclassified as a second graph rewrite')
        if [r['site_id'] for r in roles]!=[r['replacement_site_id'] for r in items]:
            raise ValueError('factory roles detached from source sites')
        if [r['replacement_call'] for r in items]!=['ReplaceWithNewInstruction','CreateUniformCollectiveReplacement']:
            raise ValueError('unexpected collective factory or replacement')
        outer,inner=[calls[(r['replacement_line'],r['replacement_call'])] for r in items]
        if not outer['byte_start']<inner['byte_start']<inner['byte_end']<outer['byte_end']:
            raise ValueError('factory not a nested replacement argument')


def main():
    inventory=json.loads((ROOT/'census/source-sites.json').read_text())
    structural=json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    source=(ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions={d['name']:d for d in inventory['definitions']}
    cases=[]
    def add(owner,slug,ordinals,lhs,rhs,guard,deps,helpers=(),collective=False):
        d=definitions[owner];body='\n'.join(source[d['line']-1:d['end_line']])
        row=dict(id=owner+'/'+slug,handler=owner,line=d['line'],end_line=d['end_line'],lhs=lhs,rhs=rhs,guard=guard,
                 source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                 status='source_extracted_pending_independent_review',proof=None,
                 path_condition='legal HLO and source-order earlier paths/status checks apply; caller context is part of the obligation',
                 dependencies=deps,helper_contract_ids=list(helpers),
                 type_partition_status='scalar types, layouts, group modes and observation profiles not exhaustively split')
        if isinstance(ordinals,tuple):
            target,anchor=ordinals;assert anchor in body
            row.update(delegation_target=target,delegation_line=d['line']+body[:body.index(anchor)].count('\n'))
        else:
            if isinstance(ordinals,int):ordinals=[ordinals]
            sites=[s for s in inventory['sites'] if s['owner']==owner and s['kind']=='replacement']
            chosen=[sites[i] for i in ordinals]
            def identity(s):
                return dict(replacement_site_id=s['id'],replacement_line=s['line'],replacement_call=s['call'],replacement_source=source[s['line']-1])
            row.update(replacement_ordinals=ordinals,**identity(chosen[0]),additional_replacement_sites=[identity(s) for s in chosen[1:]])
            if collective:
                row.update(site_roles=[dict(site_id=s['id'],role=role) for s,role in zip(chosen,['graph_replacement','replacement_argument_construction'])],
                           site_order_interpretation='source_coordinates_with_nested_factory_argument',
                           acceptance_unit='one collective rewrite including its nested construction; site list is not an execution trace')
        cases.append(row)
        return row

    uniform=('MatchUniformCollectiveOperand succeeds: array output, one operand, no control dependencies, '
             'not async computation or nested under any Conditional caller; not layout-sensitive host output; '
             'operand direct ConstantScalar OR Broadcast(ConstantScalar) OR nonempty Constant with IsAllFirst')
    replacement='Constant scalar when output scalar and default-memory condition holds; otherwise scalar Broadcast with original output shape'
    collective_helpers=['IsInConditionalBranch','MatchUniformCollectiveOperand','CreateUniformCollectiveReplacement']
    for owner,op in [('HandleAllGather','AllGather'),('HandleAllToAll','AllToAll')]:
        add(owner,'uniform',[0,1],op+'(uniform_literal)',replacement,uniform,
            ['cross-device value uniformity and collective participation/deadlock semantics', 'source matching forms may be unreachable for some legal opcode shapes',
             'factory layout/constant reuse branches','device groups and channels'],collective_helpers,collective=True)
    for reduction in ('MIN','MAX'):
        add('HandleAllReduceOrReduceScatter',reduction.lower(),[0,1],
            'AllReduce or ReduceScatter(uniform_literal,reducer '+reduction+')',replacement,
            uniform+'; MatchReductionComputation returns '+reduction,
            ['external reducer matcher includes PRED And/Or as MIN/MAX','actual reduction order, NaN payloads and signed zeros',
             'eliminating collective participation needs more than scalar idempotence'],collective_helpers,collective=True)
    for profile in ('integral','floating'):
        add('HandleAllReduceOrReduceScatter','sum-'+profile,[2,3],
            'AllReduce or ReduceScatter(uniform_literal,Add)',
            'uniform replacement of host-T literal (value * static_cast<T>(group_size))',
            uniform+'; MatchReductionComputation SUM; GetReplicaGroupCountAndSize succeeds with value; output type '+profile+'; new literal initialized',
            ['replica/partition group-mode counts, iota device lists and equal participant counts',
             'host scalar cast and multiplication versus repeated HLO addition',
             'signed C++ overflow and floating rounding/exceptional behavior','factory receives no reusable scalar instruction'],
            collective_helpers,collective=True)
    for owner in ('HandleAllReduce','HandleReduceScatter'):
        add(owner,'shared-handler',('HandleAllReduceOrReduceScatter','return HandleAllReduceOrReduceScatter('),
            owner[6:]+'(x)', 'shared handler-dependent graph','unconditional wrapper delegation',
            ['retain caller opcode, shape and group configuration when instantiating shared branches'])
    add('HandleRemainder','nested',0,'Remainder(Remainder(a,b),b)','inner Remainder(a,b)',
        'denominator pointer identity; no local scalar-type/fast-math guard',
        ['Remainder floating exceptional behavior, signed remainder convention and zero divisor'])
    for signed in (False,True):
        add('HandleRemainder','power-two-'+('signed' if signed else 'unsigned'),1,'Remainder(a,constant_power_two)',
            'Select(a<0,Negate(And(Select(a<0,Negate(a),a),b-1)),And(Select(a<0,Negate(a),a),b-1))' if signed else 'And(a,b-1)',
            'integral primitive dispatch; denominator effective-scalar Constant direct or broadcast; '+
            ('signed denominator >0 and has_single_bit' if signed else 'unsigned denominator has_single_bit'),
            ['minimum signed value and modular negation','sub-byte widths, constant casts and masking','BroadcastZeros and layout update'],['TryRemainderToAnd'])
    add('HandleRemainder','iota-in-range',2,'Remainder(Iota(axis),Broadcast(divisor))','Iota(axis)',
        'divisor ConstantEffectiveScalar; GetFirstInteger succeeds; divisor>0 and divisor>=axis extent; extent==0 OR extent-1 FitsInIntegralType',
        ['empty axes are explicitly allowed','primitive_util::FitsInIntegralType and Iota representation'])
    for side in ('lhs','rhs'):
        add('HandleRemainder','iota-add-'+side,3,'Remainder(Add(Iota, Broadcast(N)),Broadcast(N)) with Iota at '+side,
            'Remainder(Iota,Broadcast(N))','same addend/divisor ConstantEffectiveScalar pointer; GetFirstInteger positive; extent>0; extent-1 FitsInIntegralType; OverflowSafeAdd(N,extent-1) succeeds and result fits element type',
            ['source checks overflow instead of assuming integer-real equivalence','signed remainder and Iota range','OverflowSafeAdd builtin/fallback implementations'])
    rotate_guard=('mode Rotate; accumulate shifts by dimension across whole consecutive Rotate chain; '
                  'base operand is after chain; drop axes of size<=1, literal IsAllFirst splats, or Broadcast-created axes; '
                  'remaining shifts normalized with shuffle::NormalizeShift and zero results dropped')
    add('HandleShuffle','rotate-identity',0,'Rotate chain(x)', 'base x',rotate_guard+'; new_dimensions empty',
        ['sum of shifts is signed int64 before modular normalization','constant bit equality and broadcast axis membership','zero extents and legal dimension lists'])
    add('HandleShuffle','rotate-canonical',1,'Rotate chain(x)', 'Rotate(base,sorted new_dimensions,new_shifts)',
        rotate_guard+'; new_dimensions nonempty; base differs from immediate operand OR dimensions differ OR shifts differ',
        ['shift aggregation and NormalizeShift bounds/overflow','chain traversal and dimension ordering','logical rotation index direction'])
    add('TryToSinkBroadcastAfterElementwiseOps','eligible-user',0,'Elementwise(Broadcast(x,dims), compatible broadcast operands)',
        'Broadcast(cloned Elementwise of smaller operands,dims), replacing all uses of each eligible user',
        'input Broadcast and output nonscalar; user live, not Copy or Fusion, IsElementwise; every user operand scalar Broadcast OR equal-input-shape Broadcast with same dimensions',
        ['loop over all eligible users; helper can rewrite several nodes per call','scalar operands rebroadcast to changed shape','user result element type preserved in changed shape',
         'ReplaceAllUsesWith affects graph users rather than replacing visited Broadcast','caller layout/option restrictions still to reconcile'])

    summaries={
        'IsInConditionalBranch':'walk transitive caller computations with visited set; any Conditional caller rejects collective folding; preserves a distributed participation concern',
        'MatchUniformCollectiveOperand':'reject multioperand/nonarray/control/async/conditional/host cases; match direct/broadcast scalar constant or nonempty uniform literal',
        'CreateUniformCollectiveReplacement':'construct scalar Constant for scalar/default-memory output, otherwise Broadcast; optionally reuse suitable scalar; may add nodes and assign layout, does not itself replace the collective',
        'TryRemainderToAnd':'integral single-bit denominator lowering: signed sign-select/modular-negate/mask/sign-select or unsigned mask; other cases return null'}
    helpers=[]
    for name,summary in summaries.items():
        matches=[f for f in structural['functions'] if name+'(' in f['declarator']];assert len(matches)==1,name
        f=matches[0];body='\n'.join(source[f['line']-1:f['end_line']])
        helpers.append(dict(id=name,line=f['line'],end_line=f['end_line'],source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=summary,status='source_inspected_pending_independent_semantic_review'))
    output=dict(schema=1,status='partial_source_extraction',source_sha256=inventory['source_sha256'],denominator_frozen=False,
                selected_handlers=sorted({c['handler'] for c in cases}),cases=cases,helper_contracts=helpers,
                external_contract_sources='sources/collective-contract-manifest.json',
                limitations=['source schemas are not a disjoint/frozen rewrite denominator','construction factory calls are not extra graph rewrites',
                             'distributed effects, external group/reducer semantics, host arithmetic and layout remain unproved',
                             'primary-agent source inspection; independent review and full profile splitting pending'])
    validate_batch(output,inventory,source);validate_helpers(output,source);validate_site_roles(output,structural)
    (ROOT/'census/collective-rotation-cases.json').write_text(json.dumps(output,indent=2)+'\n')
    print(f'Extracted {len(cases)} collective/remainder/rotation/broadcast-user schemas across {len(output["selected_handlers"])} handlers/helpers')


if __name__=='__main__':main()
