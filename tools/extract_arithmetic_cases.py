"""Inspected arithmetic/Compare schemas; no independent review or proof implied."""
import hashlib
import json
from pathlib import Path
from extract_scalar_control_cases import validate_batch

ROOT = Path(__file__).resolve().parents[1]


def validate_helpers(batch, source):
    helpers = batch['helper_contracts']
    ids = {h['id'] for h in helpers}
    if len(ids) != len(helpers):
        raise ValueError('duplicate helper contract')
    if any(not set(c['helper_contract_ids']) <= ids for c in batch['cases']):
        raise ValueError('unresolved local helper contract')
    for helper in helpers:
        body = '\n'.join(source[helper['line'] - 1:helper['end_line']])
        if helper['id'] + '(' not in body:
            raise ValueError('wrong helper source identity')
        if hashlib.sha256(body.encode()).hexdigest() != helper['source_body_sha256']:
            raise ValueError('stale helper body')
        if helper['status'] != 'source_inspected_pending_independent_semantic_review':
            raise ValueError('helper contract promoted without review')


def main():
    inventory = json.loads((ROOT / 'census/source-sites.json').read_text())
    structural = json.loads((ROOT / 'census/normalized-structural-sites.json').read_text())
    source = (ROOT / 'sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc').read_text().splitlines()
    definitions = {d['name']: d for d in inventory['definitions']}
    cases = []

    def add(owner, slug, ordinals, lhs, rhs, guard, dependencies, helpers=()):
        definition = definitions[owner]
        body = '\n'.join(source[definition['line'] - 1:definition['end_line']])
        sites = [s for s in inventory['sites'] if s['owner'] == owner and s['kind'] == 'replacement']
        if isinstance(ordinals, int):
            ordinals = [ordinals]
        chosen = [sites[i] for i in ordinals]
        def identity(site):
            return dict(replacement_site_id=site['id'], replacement_line=site['line'],
                        replacement_call=site['call'], replacement_source=source[site['line'] - 1])
        cases.append(dict(id=owner + '/' + slug, handler=owner, line=definition['line'],
                          end_line=definition['end_line'], lhs=lhs, rhs=rhs, guard=guard,
                          path_condition='legal input HLO; source-order earlier branches, early returns and matcher binding dataflow apply',
                          status='source_extracted_pending_independent_review', proof=None,
                          source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                          replacement_ordinals=ordinals, **identity(chosen[0]),
                          additional_replacement_sites=[identity(s) for s in chosen[1:]],
                          acceptance_unit='complete source case including sequential operand writes and final replacement',
                          dependencies=dependencies, helper_contract_ids=list(helpers),
                          type_partition_status='legal types and numerical permission profiles not exhaustively split'))

    compat = ['IsAll representation and signed-zero matching', 'ReplaceInstructionIfCompatible', 'SameShape']
    reassociate = 'output neither floating nor complex OR enable_fast_math'
    for side, ordinal in [('rhs', 0), ('lhs', 1)]:
        add('HandleAdd', side + '-zero', ordinal, 'Add(x,0) with zero at ' + side, 'x',
            'IsAll(' + side + ',0); compatibility replacement succeeds; no local fast-math guard', compat)
    add('HandleAdd', 'constant-right', 2, 'Add(Constant(c),NonConstant(x))', 'Add(x,c)',
        'exact direct-Constant matcher', ['commutativity under selected scalar/NaN observation contract'])
    for broadcast in (False, True):
        form = 'broadcast-scalars' if broadcast else 'direct-constants'
        add('HandleAdd', 'constant-sum-' + form, 3, 'Add(Add(a,c1),c2) with ' + form,
            'Add(a,Add(c1,c2)), rebroadcasting constant sum when scalar result and nonscalar output',
            reassociate + '; a NonConstant; exact selected direct/broadcast Constant match',
            ['MakeBinaryHlo', 'CreateBroadcast', 'finite-width addition and independently specified fast-math relation'])
        add('HandleAdd', 'constant-subtract-' + form, 4, 'Add(Subtract(c1,a),c2) with ' + form,
            'Subtract(Add(c1,c2),a), rebroadcasting scalar constant sum if needed',
            reassociate + '; a NonConstant; exact selected direct/broadcast Constant match',
            ['MakeBinaryHlo', 'CreateBroadcast', 'subtraction/addition rounding or modular arithmetic'])
    for side in ('lhs', 'rhs'):
        add('HandleAdd', 'cancel-subtract-' + side, 5, 'Add(x,Subtract(y,x)) with Subtract at ' + side, 'y',
            'AddAnyOrder matcher; same x pointer; integral output OR enable_fast_math; compatibility succeeds', ['pointer identities', 'SameShape', 'modular or fast-math contract'])
        add('HandleAdd', 'partial-update-' + side, 6, 'Add(x,DynamicUpdateSlice(Broadcast(0),u,i)) with update at ' + side,
            'DynamicUpdateSlice(x,Add(DynamicSlice(x,i,update_shape),u),i)',
            'AddAnyOrder matcher; DUS base Broadcast(ConstantEffectiveScalar(0)); no local fast-math guard',
            ['matcher captures may rebind lhs/rhs locals', 'matching slice/update index clamping', 'addition zero behavior outside update', 'CreateDynamicSlice', 'CreateDynamicUpdateSlice'])
    for left_factor_side in ('lhs', 'rhs'):
        for right_factor_side in ('lhs', 'rhs'):
            add('HandleAdd', 'factor-' + left_factor_side + '-' + right_factor_side, 7,
                'Add(Multiply(a,c),Multiply(b,c)) with shared c at ' + left_factor_side + '/' + right_factor_side,
                'Multiply(Add(a,b),c)',
                'shared c pointer; both Multiply nodes one user; integral output OR enable_floats_are_real OR IsAllFpConstantPowerOf2(c)',
                ['source explicitly permits some floating rounding/overflow/underflow differences', 'finite-width distributivity', 'one-use matcher dataflow'], ['IsAllFpConstantPowerOf2'])
    scatter_match = ('layout insensitive; both operands Scatter with one use; both reducer roots Add(Parameter,Parameter); '
                     'index ranks equal; concat-dimension loop does not early-return; selected concat axis is not scalar sentinel; '
                     'sum of update element counts < lhs result element count')
    concat_guard = ('both scatters not unique and not sorted; all six dimension-number fields equal; '
                    'index element types equal; filtered update window dimensions equal')
    add('HandleAdd', 'scatter-concat', 8, 'Add(Scatter(base1,i1,u1),Scatter(base2,i2,u2))',
        'Scatter(Add(base1,base2),Concat(i1,i2,index_axis),Concat(u1,u2,update_axis),lhs_reducer,lhs_dnums,false,false)',
        scatter_match + '; ' + concat_guard,
        ['concat-dimension and update_dim loops', 'Scatter collision/reduction ordering', 'parameter identities in reducer body', 'integer count overflow', 'MakeConcatHlo'])
    add('HandleAdd', 'scatter-nested', [9, 10, 11], 'Add(lhsScatter,rhsScatter)',
        'lhsScatter mutated to base=rhsScatter mutated to base=Add(lhs_base,rhs_base)',
        scatter_match + '; concat safety conjunction fails',
        ['rhs base mutation precedes lhs base mutation and final Add replacement', 'one-use reachability and aliases', 'reducer reassociation and NaN/overflow behavior'])
    for side, ordinals in [('rhs', [12, 13]), ('lhs', [14, 15])]:
        add('HandleAdd', 'scatter-single-' + side, ordinals, ('Add(x,Scatter_f(base,i,u))' if side=='rhs' else 'Add(Scatter_f(base,i,u),x)'),
            ('existing Scatter_f mutated to base=Add(x,base)' if side=='rhs' else 'existing Scatter_f mutated to base=Add(base,x)'),
            'layout insensitive; only ' + side + ' local scatter-match flag true; matched Scatter one use; reducer root Add(Parameter,Parameter)',
            ['operand0 mutation then final replacement', 'scatter reducer effects, identities and order', 'other graph uses and aliases'])

    for case in cases:
        if case['id'].startswith('HandleAdd/scatter-'):
            case['reducer_role_profiles']=['00','01','10','11']
            case['matcher_checks_parameter_numbers']=False
            case['matcher_checks_parameter_distinctness']=False
            case['reducer_role_obligation']='Add(Parameter(),Parameter()) checks opcodes, not parameter roles; repeated roles are legal HLO'
            case['guard']+='; Parameter0/Parameter1 identities and distinctness are NOT checked'
            if case['id'].startswith('HandleAdd/scatter-single-'):
                case['single_update_word_profile']='distinct roles suffice for word arithmetic; repeated roles admit concrete value changes; graph/float contracts separate'

    add('HandleDivide', 'one', 0, 'Divide(a,1)', 'a', 'IsAll(denominator,1); compatibility succeeds', compat)
    for signed in (False, True):
        add('HandleDivide', 'power-two-' + ('signed' if signed else 'unsigned'), 1, 'Divide(a,constant_power_of_two)',
            'Select(a<0,Negate(LSR(Select(a<0,Negate(a),a),log2(b))),LSR(Select(a<0,Negate(a),a),log2(b)))' if signed else 'ShiftRightLogical(a,log2(b))',
            'integral primitive dispatch; effective-scalar Constant direct or broadcast; ' +
            ('signed element type; int64 denominator >0 and has_single_bit' if signed else 'unsigned element type; uint64 denominator has_single_bit'),
            ['modular negation of minimum signed value', 'logical shift amount width', 'signed division truncation', 'NativeTypeOf includes legal sub-byte types'], ['TryDivideToShift'])
    for slug, ordinal, lhs, rhs, guard, deps in [
        ('exp-pair', 2, 'Divide(Exp(a),Exp(b))', 'Exp(Subtract(a,b))', 'enable_fast_math', ['Exp domain/rounding and complex branches']),
        ('exp-denominator', 3, 'Divide(a,Exp(b))', 'Multiply(a,Exp(Negate(b)))', 'enable_fast_math', ['Exp/Negate exceptional behavior']),
        ('power-denominator', 4, 'Divide(a,Power(b,c))', 'Multiply(a,Power(b,Negate(c)))', 'output not integral; no local fast-math guard', ['Power exponent type/shape and branch conventions']),
        ('sqrt-denominator', 5, 'Divide(a,Sqrt(b))', 'Multiply(a,Rsqrt(b))', 'Sqrt one use; no local fast-math guard', ['rounding, overflow, subnormals and signed zeros']),
        ('rsqrt-denominator', 6, 'Divide(a,Rsqrt(b))', 'Multiply(a,Sqrt(b))', 'Rsqrt one use; no local fast-math guard', ['rounding, overflow, subnormals and signed zeros'])]:
        add('HandleDivide', slug, ordinal, lhs, rhs, guard, deps)
    nonintegral = 'after integral-output early return; '
    for broadcast in (False, True):
        add('HandleDivide', 'constant-' + ('broadcast' if broadcast else 'direct'), 7,
            'Divide(NonConstant(a),' + ('Broadcast(Constant(c),dims)' if broadcast else 'Constant(c)') + ')',
            'Multiply(a,' + ('Broadcast(inverted_literal,dims)' if broadcast else 'inverted_literal') + ')',
            nonintegral + 'literal primitive dispatch floating OR complex; InvertConstant succeeds; no local fast-math guard',
            ['Literal::Populate', 'host NativeT division and conversion/rounding', 'CreateConstantWithLayoutUpdated', 'rebroadcast original shape/dimensions'], ['InvertConstant'])
    add('HandleDivide', 'broadcast-reciprocal', 8, 'Divide(a,Broadcast(b,dims))', 'Multiply(a,Broadcast(Divide(1,b),dims))',
        nonintegral + 'executing_on_cpu; enable_sink_broadcast; enable_fast_math; broadcast input b has one use',
        ['intermediate reciprocal rounding explicitly documented in source', 'MakeScalarLike', 'shape/layout preservation'])
    for slug, ordinal, lhs, rhs in [
        ('fractions', 9, 'Divide(Divide(a,b),Divide(c,d))', 'Divide(Multiply(a,d),Multiply(b,c))'),
        ('nested-numerator', 10, 'Divide(Divide(a,b),c)', 'Divide(a,Multiply(b,c))'),
        ('nested-denominator', 11, 'Divide(a,Divide(b,c))', 'Divide(Multiply(a,c),b)')]:
        add('HandleDivide', slug, ordinal, lhs, rhs, nonintegral + 'exact Divide matcher; no local fast-math guard',
            ['MakeBinaryHlo', 'rounding, exceptional values and complex division semantics'])
    add('HandleDivide', 'predicate-scalar-broadcast', 12, 'Divide(Convert(pred),Broadcast(scalar_b))',
        'Multiply(Broadcast(Divide(1,b)),Convert(pred))',
        nonintegral + 'Convert input PRED; denominator broadcast input scalar; no local fast-math guard',
        ['false predicate and exceptional/zero denominators', 'source multiplies with reciprocal first', 'MakeScalarLike'])

    for owner, operation, extremum in [('HandleMaximum', 'Maximum', 'MinValue'), ('HandleMinimum', 'Minimum', 'MaxValue')]:
        add(owner, 'self', 0, operation + '(x,x)', 'x', 'same operand pointers', ['NaN payload/quieting and exact observation relation'])
        for side, ordinal in [('lhs', 1), ('rhs', 2)]:
            add(owner, side + '-extreme', ordinal, operation + '(x,extreme) with extreme at ' + side, 'x',
                'integral output OR (floating output AND minmax_propagate_nan); extreme is LiteralUtil::' + extremum + '(extreme operand type); remaining operand element type equals result type',
                ['mixed floating operand/result types', 'LiteralUtil extrema', 'IsAll', 'NaN propagation and signed zero'])
        for repeated_side in ('lhs', 'rhs'):
            add(owner, 'nested-left-' + repeated_side, 3, operation + '(' + operation + '(x,y),repeated_operand)',
                'inner ' + operation + '(x,y)',
                'outer lhs opcode same min/max; outer rhs pointer equals inner ' + repeated_side + ' operand',
                ['operand-order-sensitive NaN sign/payload behavior'])
        add(owner, 'nested-right-first', 4, operation + '(x,' + operation + '(x,y))', 'inner ' + operation + '(x,y)',
            'inner lhs pointer equals outer lhs', ['ordered min/max NaN behavior'])
        add(owner, 'nested-right-second', 5, operation + '(y,' + operation + '(x,y))', operation + '(y,x)',
            'inner rhs pointer equals outer lhs; mutate outer operand1 to inner operand0',
            ['ReplaceOperandWith and MarkAsChanged', 'source explicitly retains operand order to preserve NaN sign'])
        for outer_side in ('lhs', 'rhs'):
            for inner_side in ('lhs', 'rhs'):
                add(owner, 'clamp-' + outer_side + '-' + inner_side, 6,
                    'Maximum(lower,Minimum(x,upper))' if operation == 'Maximum' else 'Minimum(upper,Maximum(x,lower))',
                    'Clamp(lower_broadcast,x,upper_broadcast)',
                    'outer bound at ' + outer_side + '; inner bound at ' + inner_side +
                    '; both bounds Broadcast(ConstantEffectiveScalar); MinMaxToClamp returns nonnull after literal scalar reshape and evaluator lower<upper',
                    ['AnyOrder matching versus NaN order', 'Clamp numerical semantics', 'status propagation'], ['MinMaxToClamp'])
    for side in ('lhs', 'rhs'):
        add('HandleMaximum', 'clamp-lower-' + side, 7, 'Maximum(lower,Clamp(lower,x,upper)) with Clamp at ' + side,
            'matched Clamp', 'max operand pointer equals clamp lower bound; compatibility replacement succeeds',
            ['SameShape', 'Clamp exceptional values and signed-zero semantics'])
    for function in ('Cbrt', 'Erf', 'Logistic', 'Tanh'):
        add('HandleMaximum', 'sink-' + function.lower(), 8, 'Maximum(' + function + '(x),' + function + '(y))',
            function + '(Maximum(x,y))', 'both unary opcodes ' + function + '; IsNondecreasingSublinear(lhs) true',
            ['actual scalar implementation monotonicity and NaN behavior', 'MakeBinaryHlo', 'no local fast-math guard'], ['IsNondecreasingSublinear'])

    for slug,ordinal,lhs,rhs,guard in [
        ('unsigned-lt-zero',0,'Lt(x,0)','false','lhs element type unsigned integral; direction Lt; IsAll(rhs,0)'),
        ('unsigned-ge-zero',1,'Ge(x,0)','true','lhs element type unsigned integral; direction Ge; IsAll(rhs,0)'),
        ('unsigned-zero-gt',2,'Gt(0,x)','false','lhs element type unsigned integral; direction Gt; IsAll(lhs,0)'),
        ('unsigned-zero-le',3,'Le(0,x)','true','lhs element type unsigned integral; direction Le; IsAll(lhs,0)'),
        ('nonnegative-lt',4,'Lt(x,0)','false','direction Lt; IsNonNegative(lhs,options); IsAll(rhs,0)'),
        ('nonnegative-gt',5,'Gt(0,x)','false','direction Gt; IsAll(lhs,0); IsNonNegative(rhs,options)'),
        ('nonnegative-ge',6,'Ge(x,0)','true','direction Ge; IsNonNegative(lhs,options); IsAll(rhs,0)'),
        ('nonnegative-le',7,'Le(0,x)','true','direction Le; IsAll(lhs,0); IsNonNegative(rhs,options)')]:
        add('HandleCompare',slug,ordinal,lhs,'MakeScalarLike(compare,'+rhs+')',guard,
            ['source comparison_type and operand type semantics','IsAll and IsNonNegative contracts','floating NaN/signed-zero behavior where legal'])
    for direction in ('Gt','Lt','Ne','Eq','Ge','Le'):
        result=direction in ('Eq','Ge','Le')
        add('HandleCompare','integral-self-'+direction.lower(),9 if result else 8,
            direction+'(x,x)','MakeScalarLike(compare,'+str(result)+')',
            'same operand pointers; lhs type integral; direction '+direction,
            ['comparison_type compatibility and finite-width ordering','PRED is handled by later distinct branches where not integral'])
    for direction,value,base in [('Ne','false',10),('Eq','true',12)]:
        for side,offset in [('rhs',0),('lhs',1)]:
            add('HandleCompare','predicate-'+direction.lower()+'-'+side,base+offset,
                direction+'(x,'+value+') with constant at '+side,'other predicate operand',
                'both operand shapes PRED; direction '+direction+'; IsAll('+side+','+value+')',
                ['Boolean comparison meaning','ReplaceInstruction graph/type contract'])
    add('HandleCompare','causal-mask',14,'Ne(Select(Ge(a,b),ones,zeros),zeros)','inner Ge(a,b)',
        'direction Ne; IsAll(rhs,0); lhs Select with Compare Ge predicate; true value IsAll(1); false value IsAll(0); SameShape(outer result,inner predicate)',
        ['value types and numeric conversion of one/zero','scalar/tensor Select predicate legality','SameShape and metadata'])
    for slug,ordinal,lhs,rhs,guard in [
        ('maximum-first',15,'Gt(Maximum(a,b),a)','Gt(b,a)','lhs Maximum; rhs pointer == a'),
        ('maximum-second',16,'Gt(Maximum(a,b),b)','Gt(a,b)','lhs Maximum; rhs pointer == b; prior rhs==a branch excluded'),
        ('minimum-first',17,'Gt(a,Minimum(a,b))','Gt(a,b)','lhs Maximum matcher fails; rhs Minimum; lhs pointer == a'),
        ('minimum-second',18,'Gt(b,Minimum(a,b))','Gt(b,a)','lhs Maximum matcher fails; rhs Minimum; lhs pointer == b; prior lhs==a branch excluded')]:
        add('HandleCompare',slug,ordinal,lhs,rhs,'direction Gt; '+guard,
            ['mutates existing Compare operand and calls MarkAsChanged','comparison attributes retained','min/max NaN and total-order semantics; no local fast-math guard'])

    helper_summaries = {
        'IsAllFpConstantPowerOf2': 'direct effective-scalar Constant OR Broadcast(Constant effective scalar); GetConstantValue succeeds; frexp mantissa == +/-0.5',
        'TryDivideToShift': 'integral dispatcher only; signed positive single-bit denominator uses select/negate/logical-shift/select; unsigned single-bit denominator uses logical shift; other paths return null',
        'InvertConstant': 'Literal::Populate<T> with T{1.0}/constant literal element at every index; errors propagate',
        'MinMaxToClamp': 'reshape effective-scalar literals to rank0; evaluate lower<upper; return Clamp only when all comparison results true; else null; status errors propagate',
        'IsNondecreasingSublinear': 'opcode whitelist Cbrt, Erf, Logistic, Tanh; classification alone is not a proof of numeric monotonicity'}
    helpers = []
    for name, summary in helper_summaries.items():
        matches = [f for f in structural['functions'] if name + '(' in f['declarator']]
        assert len(matches) == 1, name
        function = matches[0]
        body = '\n'.join(source[function['line'] - 1:function['end_line']])
        helpers.append(dict(id=name, line=function['line'], end_line=function['end_line'],
                            source_body_sha256=hashlib.sha256(body.encode()).hexdigest(),
                            source_behavior=summary, status='source_inspected_pending_independent_semantic_review'))
    output = dict(schema=1, source_sha256=inventory['source_sha256'], status='partial_source_extraction',
                  denominator_frozen=False, selected_handlers=sorted({c['handler'] for c in cases}), cases=cases,
                  helper_contracts=helpers,
                  limitations=['primary-agent extraction, not independent semantic review',
                               'all lexical replacement sites in selected handlers mapped, but indirect writes and type/option splitting remain open',
                               'helper summaries describe inspected source behavior, not proved scalar contracts',
                               'source explicitly documents some default floating distributivity error permissions',
                               'zero accepted whole-source rewrites; do not sum cases as a rewrite denominator'])
    validate_batch(output, inventory, source)
    validate_helpers(output, source)
    assert all(set(c['helper_contract_ids']) <= set(helper_summaries) for c in cases)
    (ROOT / 'census/arithmetic-cases.json').write_text(json.dumps(output, indent=2) + '\n')
    print(f'Extracted {len(cases)} arithmetic schemas across {len(output["selected_handlers"])} handlers; {len(helpers)} inspected helper contracts')


if __name__ == '__main__':
    main()
