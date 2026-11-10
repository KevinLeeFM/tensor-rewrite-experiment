"""Inspected dot and shared primitive schemas; no source acceptance implied."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch
from extract_arithmetic_cases import validate_helpers
from reconcile_sites import noncall_declarations

ROOT = Path(__file__).resolve().parents[1]


def validate_dot_batch(batch, inventory, source, structural):
    excluded = [s['id'] for s in noncall_declarations(inventory, structural)
                if s['owner'] in batch['selected_handlers']]
    if batch['noncall_declaration_site_ids'] != excluded:
        raise ValueError('unjustified shared-helper declaration exclusion')
    validate_batch(batch, inventory, source, excluded)
    validate_helpers(batch, source)
    hooks = {'SupportedDotPrecisionConfig', 'MakeMultiplyForPrecisionAlgorithm',
             'ShouldStrengthReduceDotToReduce'}
    if set(batch['virtual_hook_contract_ids']) != hooks:
        raise ValueError('virtual dispatch scope missing')
    for case in batch['cases']:
        if case['visitor_scope'] != 'base AlgebraicSimplifierVisitor; virtual overrides require separate contracts':
            raise ValueError('base helper behavior generalized to virtual overrides')


def main():
    inventory = json.loads((ROOT/'census/source-sites.json').read_text())
    structural = json.loads((ROOT/'census/normalized-structural-sites.json').read_text())
    source = (ROOT/'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    cases = []

    def add(owner, slug, ordinals, lhs, rhs, guard, dependencies, helpers=(), overload=None):
        ds = [d for d in inventory['definitions'] if d['name'] == owner]
        if overload is not None:
            ds = [d for d in ds if d['line'] == overload]
        assert len(ds) == 1, (owner, ds)
        d = ds[0]
        body = '\n'.join(source[d['line']-1:d['end_line']])
        row = dict(id=owner+'/'+slug, handler=owner, line=d['line'], end_line=d['end_line'],
                   source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                   lhs=lhs, rhs=rhs, guard=guard, dependencies=dependencies,
                   helper_contract_ids=list(helpers), proof=None,
                   status='source_extracted_pending_independent_review',
                   path_condition='legal input HLO; all earlier source-order returns, caller guards and helper success apply; helper/body schemas overlap',
                   visitor_scope='base AlgebraicSimplifierVisitor; virtual overrides require separate contracts',
                   type_partition_status='scalar types, numerical permissions, dynamic shapes, layout and precision profiles not exhaustively split')
        if isinstance(ordinals, tuple):
            target, anchor = ordinals
            assert anchor in body
            row.update(delegation_target=target, delegation_line=d['line']+body[:body.index(anchor)].count('\n'))
        else:
            if isinstance(ordinals, int): ordinals = [ordinals]
            owned = [s for s in inventory['sites'] if s['owner'] == owner and s['kind'] == 'replacement']
            chosen = [owned[i] for i in ordinals]
            def identity(s):
                return dict(replacement_site_id=s['id'], replacement_line=s['line'],
                            replacement_call=s['call'], replacement_source=source[s['line']-1])
            row.update(replacement_ordinals=ordinals, **identity(chosen[0]),
                       additional_replacement_sites=[identity(s) for s in chosen[1:]])
        cases.append(row)
        return row

    add('ReplaceWithBitcast', 'unary', 1, 'unary instruction with supplied or default operand',
        'Bitcast with original result shape', 'CHECK operand_count1 and equal ByteSizeOf(result,operand)',
        ['caller must justify physical bitcast semantics; byte equality alone is insufficient',
         'CHECK_OK replacement abort behavior, sharding and control effects'])
    add('ReplaceInstructionIfCompatible', 'single', 1, 'old instruction', 'existing new instruction',
        'no old control predecessors; SameShape(old,new)',
        ['ReplaceInstruction preserves sharding and frontend attributes; StatusOr.value failure path',
         'returned Boolean depends on successful replacement'], ['SameShape'], overload=861)
    add('ReplaceInstructionIfCompatible', 'span-single', 3, 'old instruction; new instruction span of size1',
        'single-instruction overload', 'no old control predecessors; span.size1',
        ['same-named overload dispatch; inherited compatibility guard'], ['SameShape'], overload=882)
    add('ReplaceInstructionIfCompatible', 'span-tuple', 4, 'old tuple; multiple replacement components',
        'MaybeMakeTuple(new_instructions)',
        'no old control predecessors; span size !=1; CHECK nonempty; old tuple arity matches; every component SameShape',
        ['tuple construction; preserve sharding/frontend attributes; StatusOr.value failure path'], ['SameShape'], overload=882)
    for op in ('Add', 'Subtract', 'Multiply', 'Divide', 'Remainder'):
        add('TryRemoveUpcastAndDowncastSurroundingBinaryOp', op.lower(), 0,
            'Convert(op(Convert(a),Convert(b)))', 'op(a,b) cloned at original narrow type',
            'both inner Converts and binary op one user; inputs and final types equal; input and wide op integral, non-subbyte, same signedness; CastPreservesValues(input,wide); '+
            ('wide Divide/Remainder unsigned' if op in ('Divide', 'Remainder') else 'exact '+op+' matcher'),
            ['narrow modular arithmetic versus widening/truncation; division by zero behavior',
             'CloneWithNewOperands copies opcode attributes; no shape/rank change'])

    common = 'HandleDot caller: operand_count<=2; layout insensitive; no earlier successful rewrite; '
    dot_helpers = ['ConstructToDotMaps', 'ConstructFromDotMaps']
    for direct in (True, False):
        add('RemoveDegenerateDimensionFromDot', 'direct' if direct else 'reshape-result', 0 if direct else 1,
            'Dot with some extent-one operand axes',
            'Dot of reshaped operands with deleted/renumbered unit axes'+('' if direct else ', then Reshape to original result'),
            common+'some lhs or rhs unit axis; ShapeUtil.Compatible(new_dot,old)='+str(direct),
            ['pairwise extent equality links removed batch/contracting axes', 'precision and result element type retained',
             'fallback preserve_sharding=false and relay_control_dependency=true', 'dynamic unit axes versus static extent'], dot_helpers)
    for swap in (False, True):
        add('RemoveTransposesFromDotOperands', 'swap' if swap else 'keep-order', 0,
            'Dot(Transpose(a,p),Transpose(b,p))', 'Transpose(Dot('+('b,a' if swap else 'a,b')+'),outer_permutation)',
            common+'equal input transpose permutations; lhs/rhs batch lists equal; exactly one contracting axis each at rank-1/rank-2; result rank=batchcount+2; permutation suffix '+('[rank-1,rank-2]' if swap else '[rank-2,rank-1]'),
            ['batch-axis list need not be numerically canonical merely because the source comment says canonical',
             'inverse permutation shapes; swap operand precision when swapping inputs; SetupDerivedInstruction'])
    add('MoveDotParamToRhs', 'parameter-left', 0, 'Dot(parameter-like a,non-parameter-like b)',
        'Transpose(Dot(b,a),batch/rhs-free/lhs-free permutation)',
        common+'enable_move_dot_param_to_rhs; IsParameterLike(lhs) and not IsParameterLike(rhs)',
        ['swap batch/contracting lists and operand precision entries',
         'SetupDerivedInstruction fusion attribute choices; final preserve_frontend_attributes=false'], ['IsParameterLike'])

    for lhs_convert in (False, True):
        for rhs_convert in (False, True):
            add('RewriteAsMultiplyDotWithZeroLhsContractingDim', 'casts-'+str(int(lhs_convert))+str(int(rhs_convert)), 0,
                'Dot(a,b) without contracting axes', 'Multiply(broadcasted normalized operands converted to result type as needed)',
                'HandleDot early outer-product branch; SupportedDotPrecisionConfig(false); enable_dot_to_multiply_rewrite; no lhs contracting axes; lhs conversion='+str(lhs_convert)+'; rhs conversion='+str(rhs_convert),
                ['batch-major/free/contracting-minor normalization; output broadcast maps',
                 'source uses plain Multiply here, not MakeMultiplyForPrecisionAlgorithm', 'conversion and multiplication precision/exception behavior'],
                ['NormalizeDotOperandToBatchMajorAndContractingMinor', 'SupportedDotPrecisionConfig'])
    for inner_side in ('lhs', 'rhs'):
        for transpose in (True, False):
            add('AssociativeReorderNestedDot', inner_side+'-'+('transpose' if transpose else 'direct'), 0 if transpose else 1,
                'nested Dot at outer '+inner_side, 'oppositely associated two Dots'+(' then output Transpose' if transpose else ''),
                common+'use_associative_reordering; '+('lhs Dot (takes priority over rhs)' if inner_side=='lhs' else 'lhs not Dot; rhs Dot')+'; no outer contracting axis originates from both inner inputs; old_flops/double(new_flops)>threshold; nonidentity permutation='+str(transpose),
                ['kStopRewrites prevents later HandleDot rewrites when batch dimension contracted',
                 'map-vector equality used to identify side in batch loop', 'both new dots use OUTER dot precision config and result type',
                 'inner dot original precision/type need separate correspondence and numerical permission review',
                 'finite flop arithmetic, nonzero denominator and complete output permutation'], dot_helpers)
    for side in ('lhs', 'rhs', 'both'):
        add('RewriteBatchPlusContractingAsReduce', 'no-free-'+side, 0,
            'Dot with only batch/contracting axes on '+side, 'Convert(ReduceAdd(Convert(precision-specific Multiply(normalized broadcast operands))))',
            common+'SupportedDotPrecisionConfig(true); enable_dot_strength_reduction; DotHasOnlyBatchAndContractingOnOneOperand; ShouldStrengthReduceDotToReduce; free-axis partition='+side,
            ['convert operands to dot result type before multiply; F32 accumulation for floating result except F64',
             'AddReduce zero element type and scalar-add computation; final conversion', 'normalization and broadcasting rank arithmetic',
             'virtual hook behavior cannot be assumed for derived visitors'],
            ['NormalizeDotOperandToBatchMajorAndContractingMinor', 'AddReduce', 'SupportedDotPrecisionConfig',
             'MakeMultiplyForPrecisionAlgorithm', 'ShouldStrengthReduceDotToReduce', 'DotHasOnlyBatchAndContractingOnOneOperand'])

    add('HandleDot', 'empty', 0, 'Dot(a,b)', 'Broadcast(typed zero)',
        'operand_count<=2; layout insensitive; output OR lhs OR rhs has zero elements',
        ['empty output versus nonempty output with empty contraction; LiteralUtil.Zero; precision profile'])
    for owner, slug, anchor, guard in (
        ('RewriteAsMultiplyDotWithZeroLhsContractingDim','outer-product','return RewriteAsMultiplyDotWithZeroLhsContractingDim(',
         'SupportedDotPrecisionConfig(false); enable_dot_to_multiply_rewrite; no contracting axes; occurs BEFORE unreduced sharding early return'),
        ('AssociativeReorderNestedDot','nested','AssociativeReorderNestedDot(dot_cast, lhs, rhs)', 'use_associative_reordering; nested return kRewritten OR kStopRewrites stops visitor'),
        ('RewriteBatchPlusContractingAsReduce','strength-reduce','return RewriteBatchPlusContractingAsReduce(', 'SupportedDotPrecisionConfig(true); enable_dot_strength_reduction; one operand only batch and contracting axes; ShouldStrengthReduceDotToReduce'),
        ('RemoveDegenerateDimensionFromDot','degenerate','RemoveDegenerateDimensionFromDot(dot_cast)', 'earlier paths failed; helper returns changed'),
        ('RemoveTransposesFromDotOperands','transposes','RemoveTransposesFromDotOperands(dot_cast)', 'earlier paths failed; helper returns changed'),
        ('MoveDotParamToRhs','parameter-swap','MoveDotParamToRhs(dot_cast)', 'earlier paths failed; helper returns changed')):
        add('HandleDot', slug+'-delegation', (owner,anchor), 'Dot(a,b)', 'helper graph', common+guard,
            ['unreduced Sharding custom-call user veto follows outer-product branch and precedes nested branch', 'helper true/result enum and Status propagation'])

    for direction in ('lhs-to-rhs', 'rhs-to-lhs'):
        for op in ('Reverse', 'Pad', 'Broadcast'):
            add('HandleDot', 'mirror-'+op.lower()+'-'+direction, 1, 'Dot with '+op+' on '+direction.split('-')[0],
                'Dot after moving contracting-axis '+op+' to the other operand',
                common+'use_associative_reordering; helper selects lhs opcode among Broadcast/Pad/Reverse before rhs; direction='+direction+'; helper returns nonnull',
                ['Reverse splits contracting and retained axes, requires ratio threshold, final cost veto waived',
                 'Pad requires zero fill and moves eligible nonnegative contracting padding to Slice, retaining other padding',
                 'Broadcast moves introduced contracting axes to ReduceAdd and rebuilds dimension lists/broadcast shape',
                 'Pad/Broadcast require strict flop-ratio threshold with multiplier2 if residual op',
                 'can construct nodes even when final cost guard fails; finite signed dimension arithmetic',
                 'zero products, nonfinite values and reassociation require case-specific permissions'],
                ['AssociativeReorderDotOperator'])
    for constant_side in ('lhs', 'rhs'):
        add('HandleDot', 'reorder-contracting-'+constant_side, 2,
            'Dot(Reshape(Transpose(x)),Constant), with Constant on '+constant_side,
            'Dot(Reshape(x),Reshape(Transpose(Reshape(Constant)))) restoring original operand order',
            common+'OptimizeDotOfReorderContractingDims returns nonnull; virtual constant-left swap as needed; one contracting dimension; exactly one reshape-modified output dimension is contracting; unsquished contracting axes consecutive; transpose fixes other axes',
            ['matched reshape index order; inverse transpose; constant shape reconstruction',
             'permutation of reduction order; original dnums and precision retained', 'CHECK IsPermutation; no local fast-math gate'],
            ['OptimizeDotOfReorderContractingDims'])
        add('HandleDot', 'concat-'+constant_side, 3, 'Dot(Concat(xs,contracting axis),Constant), Constant on '+constant_side,
            'left-associated Add chain of Dots against disjoint Constant slices',
            common+'output rank2; exactly one contracting axis; no batch; helper tries lhs concat first then rhs; other operand rank2 Constant',
            ['cumulative slice offsets, original operand order and dot precision', 'empty concat segments and nonempty operand list',
             'split/reassociated contraction numerical permissions'], ['OptimizeDotOfConcat', 'OptimizeDotOfConcatHelper'])
    for slice_side in ('lhs', 'rhs'):
        add('HandleDot', 'dynamic-slice-'+slice_side, 4,
            'Dot(DynamicSlice(Constant),Constant) with slice on '+slice_side,
            'DynamicSlice(Dot(full Constants),reordered original start operands)',
            common+'output rank2; one contracting axis; no batches; DynamicSlice preserves full contracting extent and has free extent1; helper either-side predicate succeeds',
            ['dynamic start indices clamp including full-extent contracting axis',
             'lhs_is_dynamic_slice computed from opcode after pair test; start operand selection and dot dimensions',
             'constant evaluation versus runtime dot precision'], ['OptimizeDotOfGather'])

    summaries = {
        'SameShape': 'layout-sensitive Equal; otherwise Compatible; does not by itself justify equal values',
        'IsParameterLike': 'follow ANY unary operand chain to Parameter; no opcode whitelist or proof that each unary op is identity',
        'ConstructToDotMaps': 'input axis to output axis: batch list order then ascending lhs-free then ascending rhs-free; contracting maps to -1',
        'ConstructFromDotMaps': 'invert both ConstructToDotMaps vectors; batch output may originate in both operands',
        'DotHasOnlyBatchAndContractingOnOneOperand': 'batch+contracting counts equal lhs rank OR rhs rank; legal disjoint dimensions assumed',
        'NormalizeDotOperandToBatchMajorAndContractingMinor': 'batch list then ascending free axes then contracting list; skip transpose when sorted',
        'AddReduce': 'zero literal of input element type; scalar Add computation of requested type; delete reduced axes; update layout',
        'SupportedDotPrecisionConfig': 'BASE virtual implementation accepts ALG_UNSET or ALG_DOT_F32_F32_F32; has_contracting_dim unused',
        'MakeMultiplyForPrecisionAlgorithm': 'BASE virtual implementation returns plain MakeBinaryHlo Multiply; does not inspect dot',
        'ShouldStrengthReduceDotToReduce': 'BASE virtual implementation CPU requires BOTH inputs only batch/contracting; otherwise true',
        'OptimizeDotOfConcat': 'rank2 result, one contracting axis, no batch; try concat on lhs before swapped rhs',
        'OptimizeDotOfConcatHelper': 'contracting Concat versus rank2 Constant; slice cumulative intervals, preserve original dot operand order and precision; left-associative sum',
        'OptimizeDotOfGather': 'actually DynamicSlice(Constant), not general Gather; full contracting extent and free extent1; full Dot then DynamicSlice with remapped original indices',
        'OptimizeDotOfReorderContractingDims': 'layout insensitive; virtual constant-side swap; reshape only squishes contracting axes, consecutive unsquished axes; move transpose to constant with inverse reshape/transpose; restore original operand order',
        'AssociativeReorderDotOperator': 'lhs Broadcast/Pad/Reverse wins over eligible rhs; transfer only mapped contracting axes; cost conditions and numerical permissions described per caller schema',
    }
    helpers = []
    for name, behavior in summaries.items():
        fs = [f for f in structural['functions'] if name+'(' in f['declarator']]
        if name == 'SameShape': fs = [f for f in fs if 'const Shape&' in f['declarator']]
        assert len(fs) == 1, name
        f = fs[0]
        body = '\n'.join(source[f['line']-1:f['end_line']])
        helpers.append(dict(id=name, line=f['line'], end_line=f['end_line'],
                            source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=behavior, status='source_inspected_pending_independent_semantic_review'))
    owners = sorted({c['handler'] for c in cases})
    result = dict(schema=1, status='partial_source_extraction', source_sha256=inventory['source_sha256'],
                  denominator_frozen=False, selected_handlers=owners, cases=cases, helper_contracts=helpers,
                  noncall_declaration_site_ids=[s['id'] for s in noncall_declarations(inventory, structural) if s['owner'] in owners],
                  virtual_hook_contract_ids=['SupportedDotPrecisionConfig','MakeMultiplyForPrecisionAlgorithm','ShouldStrengthReduceDotToReduce'],
                  limitations=['schemas overlap and remain provisional; not an obligation denominator',
                               'base visitor hooks do not describe every backend override',
                               'no independently reviewed source correspondence or accepted full-source proof'])
    validate_dot_batch(result, inventory, source, structural)
    (ROOT/'census/dot-cases.json').write_text(json.dumps(result, indent=2)+'\n')
    print(f'Extracted {len(cases)} dot/shared primitive schemas across {len(owners)} owners')


if __name__ == '__main__': main()
