"""Inspected numerical/control schemas, pending semantic and independent review.

Replacement ordinals select exact pinned-source calls, not rewrite denominators.
Helper-dependent meanings are obligations; none is asserted as a proved fact.
"""
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def validate_batch(batch, inventory, source, excluded_ids=()):
    """Check identity and replacement-site coverage without claiming semantics."""
    if batch['source_sha256'] != inventory['source_sha256'] or batch['denominator_frozen']:
        raise ValueError('wrong source or premature denominator')
    cases = batch['cases']
    if len({c['id'] for c in cases}) != len(cases):
        raise ValueError('duplicate case')
    owners = set(batch['selected_handlers'])
    if {c['handler'] for c in cases} != owners:
        raise ValueError('missing handler')
    expected = {s['id']: s for s in inventory['sites'] if s['kind'] == 'replacement' and s['owner'] in owners and s['id'] not in excluded_ids}
    definitions = {(d['name'], d['line'], d['end_line']): d for d in inventory['definitions']}
    found = set()
    for case in cases:
        definition = definitions.get((case['handler'], case['line'], case['end_line']))
        if definition is None:
            raise ValueError('wrong owner bounds')
        body = '\n'.join(source[case['line'] - 1:case['end_line']])
        if hashlib.sha256(body.encode()).hexdigest() != case['source_body_sha256']:
            raise ValueError('stale source body')
        if case['proof'] is not None or case['status'] != 'source_extracted_pending_independent_review':
            raise ValueError('unreviewed source promoted')
        if 'replacement_site_id' in case:
            sequence = [case] + case.get('additional_replacement_sites', [])
            for item in sequence:
                site = expected.get(item['replacement_site_id'])
                if site is None or site['owner'] != case['handler']:
                    raise ValueError('wrong replacement owner')
                if not case['line'] <= site['line'] <= case['end_line']:
                    raise ValueError('replacement belongs to a different overload')
                if site['line'] != item['replacement_line'] or site['call'] != item['replacement_call']:
                    raise ValueError('wrong replacement identity')
                if source[site['line'] - 1] != item['replacement_source']:
                    raise ValueError('wrong replacement source')
                found.add(site['id'])
        elif case['delegation_target'] not in source[case['delegation_line'] - 1]:
            raise ValueError('wrong delegation source')
    if found != set(expected):
        raise ValueError('unmapped replacement in selected handlers')


def main():
    inventory = json.loads((ROOT / 'census/source-sites.json').read_text())
    source = (ROOT / 'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions = {d['name']: d for d in inventory['definitions']}
    cases = []

    def add(owner, slug, ordinal, lhs, rhs, guard, dependencies):
        definition = definitions[owner]
        body = '\n'.join(source[definition['line'] - 1:definition['end_line']])
        sites = [s for s in inventory['sites'] if s['owner'] == owner and s['kind'] == 'replacement']
        row = dict(id=owner + '/' + slug, handler=owner, line=definition['line'],
                   end_line=definition['end_line'], lhs=lhs, rhs=rhs, guard=guard,
                   path_condition='legal input HLO; earlier branches did not successfully rewrite; enclosing conditions apply',
                   dependencies=dependencies, source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                   status='source_extracted_pending_independent_review', proof=None,
                   type_partition_status='legal source types not yet exhaustively split')
        if isinstance(ordinal, int):
            site = sites[ordinal]
            row.update(replacement_ordinals=[ordinal], replacement_site_id=site['id'],
                       replacement_line=site['line'], replacement_call=site['call'],
                       replacement_source=source[site['line'] - 1])
        else:
            target, anchor = ordinal
            assert anchor in body
            row.update(delegation_target=target, delegation_line=definition['line'] + body[:body.index(anchor)].count('\n'))
        cases.append(row)

    add('HandleAbs', 'nonnegative', 0, 'Abs(x)', 'x', 'IsNonNegative(x,options)',
        ['IsNonNegative: expand recursive/value-range and option contract', 'Abs exceptional values and result type', 'ReplaceInstruction'])
    add('HandleClamp', 'idempotent', 0, 'Clamp(a,Clamp(a,x,b),b)', 'Clamp(a,x,b)',
        'both bound operand pointers match; ReplaceInstructionIfCompatible succeeds', ['Clamp ordered/NaN/signed-zero semantics', 'SameShape'])
    add('HandleClamp', 'runtime-id', 1, 'Clamp(0,PartitionId/ReplicaId,upper)', 'PartitionId/ReplicaId',
        'ID opcode; lower ConstantScalar(0U); upper ConstantScalar; read upper as uint32; module bound != 1 and bound <= upper+1',
        ['module replica/partition configuration and actual runtime range', 'Literal::GetFirstElement<uint32_t>', 'ReplaceInstruction'])
    add('HandleLog', 'exp', 0, 'Log(Exp(a))', 'a', 'enable_fast_math; compatibility replacement succeeds', ['independent fast-math observation contract'])
    for complex_type in (False, True):
        add('HandleLog', 'power-' + ('complex' if complex_type else 'real'), 1, 'Log(Power(a,b))',
            'Select(b == 0,0,Multiply(Log(' + ('a' if complex_type else 'Abs(a)') + '),b))',
            'enable_fast_math; a element type ' + ('complex' if complex_type else 'not complex'),
            ['complex branch cuts or real logarithm domains', 'MakeCompareHlo Eq', 'MakeScalarLike', 'UpdateLayout', 'fast-math contract'])
    add('HandleLog', 'sqrt', 2, 'Log(Sqrt(a))', 'Multiply(Log(a),0.5)',
        'Sqrt matcher; no local fast-math or domain guard', ['Log/Sqrt rounding, domains and exceptional values'])
    add('HandleLog', 'rsqrt', 3, 'Log(Rsqrt(a))', 'Multiply(Log(a),-0.5)',
        'Rsqrt matcher; no local fast-math or domain guard', ['Log/Rsqrt rounding, domains and exceptional values'])
    add('HandleConvert', 'same-type', 0, 'Convert(x,T)', 'x', 'source element type == destination element type', ['Convert semantics', 'ReplaceInstruction'])
    add('HandleConvert', 'noop-pair', 1, 'Convert(Convert(x,U),T)', 'x', 'IsConvertPairNoOp(convert)',
        ['IsConvertPairNoOp: expand all legal type pairs and precision/range predicates'])
    add('HandleConvert', 'constant-fold', 2, 'Convert(Constant(c),T)', 'Constant(Literal.Convert(c,T))',
        'use_convert_constant_folding; constant one user; 8 <= destination BitWidth <= source BitWidth; literal conversion succeeds',
        ['Literal::Convert signedness, rounding and overflow', 'status/error propagation'])
    add('HandleConvert', 'binary-surround-delegation',
        ('TryRemoveUpcastAndDowncastSurroundingBinaryOp', 'return TryRemoveUpcastAndDowncastSurroundingBinaryOp(convert)'),
        'Convert(Binary(Convert(a),Convert(b)))', 'helper-dependent graph', 'all prior branches did not rewrite',
        ['TryRemoveUpcastAndDowncastSurroundingBinaryOp: expand all branches'])
    for wrapped in (False, True):
        add('HandleCustomCall', 'dynamic-roundtrip-' + ('clamped-size' if wrapped else 'raw-size'), 0,
            'SliceToDynamic(GTE(PadToStatic(x),0),' + ('Clamp(0,GTE(PadToStatic(x),1),bound)' if wrapped else 'GTE(PadToStatic(x),1)') + ')', 'x',
            'output rank-one array; same PadToStatic instruction pointer for both GTEs; SameShape(output,x); clamped upper bound is output extent when present',
            ['PadToStatic/SliceToDynamic ABI, dynamic sizes and out-of-bound behavior', 'SameShape', 'ReplaceInstruction'])
    add('HandleCustomCall', 'layout-identity', 1, 'LayoutConstraint(x)', 'x',
        'layout sensitive; SameShape(output,x)', ['LayoutConstraint custom-call contract', 'SameShape'])
    add('HandleCustomCall', 'layout-copy', 2, 'LayoutConstraint(x)', 'Copy(x,output shape)',
        'layout sensitive; !SameShape(output,x)', ['LayoutConstraint contract', 'Copy layout/memory-space behavior'])
    power_rows = [
        ('zero', 'Power(a,0)', 'MakeScalarLike(output,1)', 'IsAll(exponent,0)', ['Power zero exponent semantics', 'MakeScalarLike']),
        ('one', 'Power(a,1)', 'a', 'IsAll(exponent,1); compatibility replacement succeeds', ['Power semantics', 'SameShape']),
        ('exp-base', 'Power(Exp(a),b)', 'Exp(Multiply(a,b))', 'enable_fast_math; Exp matcher', ['independent fast-math contract', 'complex branches']),
        ('two', 'Power(a,2)', 'Multiply(a,a)', 'IsAll(exponent,2); no local fast-math guard', ['Power versus Multiply rounding']),
        ('three', 'Power(a,3)', 'Multiply(a,Multiply(a,a))', 'IsAll(exponent,3); no local fast-math guard', ['source multiplication association', 'Power rounding']),
        ('minus-one', 'Power(a,-1)', 'Divide(1,a)', 'output not integral; IsAll(exponent,-1)', ['Power/Divide rounding and exceptional values']),
        ('half', 'Power(a,0.5)', 'Sqrt(a)', 'IsAllFloat(exponent,0.5); IsNonNegative(a,options)', ['IsAllFloat', 'IsNonNegative', 'Power/Sqrt rounding'])]
    for ordinal, (slug, lhs, rhs, guard, deps) in enumerate(power_rows):
        add('HandlePower', slug, ordinal, lhs, rhs, guard, deps)
    add('HandleRsqrt', 'inverse-square', 0, 'Rsqrt(Power(a,-2))', 'a',
        'Power opcode; IsAll(exponent,-2); IsNonNegative(a,options); no local fast-math guard', ['IsNonNegative', 'Power/Rsqrt rounding, overflow and underflow'])
    add('HandleRsqrt', 'reciprocal', 1, 'Rsqrt(Divide(1,a))', 'Sqrt(a)',
        'Divide opcode; IsAll(numerator,1); IsNonNegative(a,options); no local fast-math guard', ['IsNonNegative', 'Divide/Rsqrt/Sqrt rounding'])
    add('HandleReducePrecision', 'full-width', 0, 'ReducePrecision(x,e,m)', 'x',
        'enable_remove_no_op_reduce_precision; exponent_bits == ExponentWidth(input type); mantissa_bits+1 == SignificandWidth(input type)',
        ['ReducePrecision NaN, subnormal and signed-zero behavior', 'primitive_util widths'])
    for slug, ordinal, lhs, rhs, guard in (
        ('equal-values', 0, 'Select(p,x,x)', 'x', 'true/false operand pointer identity; compatibility replacement succeeds'),
        ('true', 1, 'Select(true,x,y)', 'x', 'IsAll(predicate,true); compatibility replacement succeeds'),
        ('false', 2, 'Select(false,x,y)', 'y', 'IsAll(predicate,false); compatibility replacement succeeds'),
        ('not-predicate', 3, 'Select(Not(p),x,y)', 'Select(p,y,x)', 'predicate opcode Not')):
        add('HandleSelect', slug, ordinal, lhs, rhs, guard, ['Select scalar-or-tensor predicate semantics', 'SameShape where used'])
    for inverted in (False, True):
        for scalar in (False, True):
            name = ('false-true' if inverted else 'true-false') + ('-broadcast' if scalar else '-direct')
            expression = 'Not(p)' if inverted else 'p'
            add('HandleSelect', name, 4, 'Select(p,' + ('false,true' if inverted else 'true,false') + ')',
                'Broadcast(' + expression + ')' if scalar else expression,
                'output PRED; IsAll(branches,listed values); replacement ' +
                ('scalar and output nonscalar' if scalar else 'not (replacement scalar and output nonscalar)'),
                ['predicate broadcasting at arbitrary rank', 'MakeBroadcastHlo', 'ReplaceInstruction'])
    for direction, ordinal, result in (('Gt', 5, 'Or(a,b)'), ('Ge', 5, 'Or(a,b)'),
                                       ('Lt', 6, 'And(a,b)'), ('Le', 6, 'And(a,b)'),
                                       ('Eq', 7, 'b'), ('Ne', 8, 'a')):
        add('HandleSelect', 'boolean-compare-' + direction.lower(), ordinal,
            'Select(Compare(a,b,' + direction + '),a,b)', result,
            'output PRED; compare operands same pointers as select true/false operands; direction ' + direction,
            ['PRED comparison ordering and comparison_type', 'Boolean operators'])
    for update_on_true in (False, True):
        for scalar in (False, True):
            branch = 'true' if update_on_true else 'false'
            pred = 'p' if scalar else 'DynamicSlice(p,i,update_shape)'
            old = 'DynamicSlice(xs,i,update_shape)'
            selected = 'Select(' + pred + ',' + ('u,' + old if update_on_true else old + ',u') + ')'
            add('HandleSelect', 'update-' + branch + ('-scalar-pred' if scalar else '-tensor-pred'), 9,
                'Select(p,' + ('DynamicUpdateSlice(xs,u,i),xs' if update_on_true else 'xs,DynamicUpdateSlice(xs,u,i)') + ')',
                'DynamicUpdateSlice(xs,' + selected + ',i)',
                'update instruction has one use; shared base pointer; predicate ' + ('scalar' if scalar else 'nonscalar'),
                ['clamping and index type for DynamicSlice and DynamicUpdateSlice', 'matching slice extents', 'layout update'])
    add('HandleScatter', 'empty-updates', 0, 'Scatter(bases,indices,updates)', 'bases (or tuple)',
        'all updates zero-element arrays; ReplaceInstructionIfCompatible with scatter_operands succeeds',
        ['variadic replacement overload and tuple handling', 'Scatter update computation side effects'])
    add('HandleScatter', 'empty-indices', 1, 'Scatter(base,empty_indices,update)', 'Map(base,update,to_apply)',
        'one scatter operand; indices zero-element array; SameShape(output,base) and SameShape(output,update)',
        ['Scatter empty index-vector interpretation versus no updates', 'scatter dimension numbers', 'Map application semantics'])
    for multiple in (False, True):
        add('HandleSort', 'trivial-' + ('tuple' if multiple else 'single'), int(multiple), 'Sort(operands,axis)',
            'Tuple(operands)' if multiple else 'operand0',
            '(operand0 zero-element array OR extent(axis)<=1); ' + ('operand_count != 1' if multiple else 'operand_count == 1'),
            ['Sort comparator effects and ordering', 'tuple value semantics'])
    for complex_type in (True, False):
        add('HandleSqrt', 'square-' + ('complex' if complex_type else 'real'), 0 if complex_type else 1,
            'Sqrt(Multiply(a,a))', 'Convert(Abs(a),complex type)' if complex_type else 'Abs(a)',
            'enable_fast_math; Multiply opcode; same operand pointers; element type ' + ('complex' if complex_type else 'not complex'),
            ['complex principal square root versus modulus', 'independently specified fast-math permissions', 'type-changing Abs and Convert'])
    add('HandleMap', 'parameter-root', 0, 'Map(operands,Parameter(k))', 'operands[k]',
        'map computation root Parameter; ReplaceInstructionIfCompatible succeeds (return value ignored by handler)',
        ['to_apply well-formedness and side effects', 'parameter indexing', 'SameShape'])
    for scalar in (True, False):
        add('HandleMap', 'constant-root-' + ('scalar' if scalar else 'broadcast'), 1 if scalar else 2,
            'Map(operands,Constant(c))', 'cloned Constant(c)' if scalar else 'Broadcast(cloned Constant(c),output shape)',
            'map root scalar Constant; output ' + ('scalar' if scalar else 'nonscalar'),
            ['Map evaluated computation and unused operations', 'constant cloning', 'broadcast'])
    add('HandleMap', 'elementwise-root', 3, 'Map(operands,Elementwise(Parameter(k0),...))',
        'clone Elementwise with output shape and selected operands[kj]',
        'root not Fusion and IsElementwise; every direct root operand Parameter',
        ['IsElementwise shape polymorphism and opcode attributes', 'CloneWithNewOperands', 'effect/call semantics'])
    add('HandleConditional', 'predicate-convert', 0, 'Conditional(Convert(p),arg0,branch0,arg1,branch1)',
        'Conditional(p,true_arg=arg1,true_branch=branch1,false_arg=arg0,false_branch=branch0)',
        'enable_conditional_simplification; selector opcode Convert; Convert input PRED; exactly two branches',
        ['integer conditional index/clamping semantics', 'PRED conversion', 'Boolean branch order', 'branch effects'])
    output = dict(schema=1, status='partial_source_extraction', denominator_frozen=False,
                  source_sha256=inventory['source_sha256'], cases=cases,
                  selected_handlers=sorted({r['handler'] for r in cases}),
                  limitations=['primary-agent extraction only; no independent source review',
                               'delegated helpers and scalar type/option profiles remain to be expanded',
                               'numeric expressions are source descriptions, not accepted algebraic identities',
                               'graph/effect/layout obligations remain open; no source rewrite accepted'])
    validate_batch(output, inventory, source)
    (ROOT / 'census/scalar-control-cases.json').write_text(json.dumps(output, indent=2) + '\n')
    print(f'Extracted {len(cases)} numerical/control schemas across {len({r["handler"] for r in cases})} handlers')


if __name__ == '__main__':
    main()
