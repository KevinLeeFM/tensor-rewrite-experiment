"""Recover the paper-era executed cases and archived results, without running XLA."""
import hashlib
import json
import re
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
INVENTORY = ROOT / 'census/historical-rules.json'
RESULT = ROOT / 'sources/tensorright/artifact/tr-artifact/plot/result.txt'
TRIAGE = OUT / 'triage.json'
RERUN = OUT / 'artifact-rerun.json'


def digest(data):
    return hashlib.sha256(data).hexdigest()


def main():
    inventory = json.loads(INVENTORY.read_text())
    cases = [r for r in inventory['rules'] if r['included_by_runall']
             and r['verifier_invocations']]
    assert len(cases) == 118 and len({r['id'] for r in cases}) == 118
    paths = list(dict.fromkeys(r['path'] for r in cases))
    assert paths == sorted(paths)
    for path in paths:
        source = (ROOT / path).read_text()
        body = source.split('main = do', 1)[1]
        calls = re.findall(r'^\s+verify\w*\s+([^\n]+)', body, re.M)
        called = [re.search(r'(\w+)\s*$', c.split('--', 1)[0]).group(1) for c in calls]
        declared = [r['id'].split('/')[1] for r in cases if r['path'] == path]
        assert called == declared, (path, called, declared)
    validation = json.loads((OUT / 'proof-check-manifest.json').read_text())
    for path, expected in validation['file_sha256'].items():
        assert digest((ROOT / path).read_bytes()) == expected, path
    project_tree = hashlib.sha256()
    for path in sorted((ROOT / 'TensorRewrite').rglob('*.lean')):
        relative = path.relative_to(ROOT).as_posix()
        project_tree.update((relative + '\0' + digest(path.read_bytes()) + '\n').encode())
    assert project_tree.hexdigest() == validation['project_lean_tree_sha256']
    result_text = RESULT.read_text()
    blocks = re.split(r'^====> ', result_text, flags=re.M)[1:]
    assert len(blocks) == len(cases)
    add_names = ['reassociate', 'zero_right', 'zero_left', 'commute']
    proofs = {f'add/rule0{i + 1}': ('Add', name) for i, name in enumerate(add_names)}
    proofs.update({
        'sub/rule00': ('ScalarArithmetic', 'sub_zero'),
        'sub/rule01': ('ScalarArithmetic', 'sub_neg'),
        'sub/rule02': ('ScalarArithmetic', 'sub_self'),
        'mul/rule01': ('ScalarArithmetic', 'mul_one_right'),
        'mul/rule02': ('ScalarArithmetic', 'mul_one_left'),
        'mul/rule03': ('ScalarArithmetic', 'mul_zero_right'),
        'mul/rule04': ('ScalarArithmetic', 'mul_zero_left'),
        'mul/rule05': ('ScalarArithmetic', 'mul_four_factors'),
        'mul/rule06': ('ScalarArithmetic', 'mul_reassociate'),
        'mul/rule08': ('ScalarArithmetic', 'mul_factor'),
        'mul/rule07': ('Broadcast', 'uniform_factor'),
        'broadcast/rule01': ('Broadcast', 'add'),
        'broadcast/rule02': ('Broadcast', 'multiply'),
        'broadcast/rule04': ('Broadcast', 'reverse_constant'),
        'logical/rule01': ('Logical', 'or_true_right'),
        'logical/rule02': ('Logical', 'or_true_left'),
        'logical/rule03': ('Logical', 'or_false_right'),
        'logical/rule04': ('Logical', 'or_false_left'),
        'logical/rule05': ('Logical', 'and_true_right'),
        'logical/rule06': ('Logical', 'and_true_left'),
        'logical/rule07': ('Logical', 'and_false_right'),
        'logical/rule08': ('Logical', 'and_false_left'),
        'not/rule01': ('Logical', 'not_not'),
        'not/rule02': ('Logical', 'neg_neg'),
        'compare/rule01': ('Comparisons', 'self_gt'),
        'compare/rule02': ('Comparisons', 'self_lt'),
        'compare/rule03': ('Comparisons', 'self_ne'),
        'compare/rule04': ('Comparisons', 'self_ge'),
        'compare/rule05': ('Comparisons', 'self_le'),
        'compare/rule06': ('Comparisons', 'self_eq'),
        'logical/rule09': ('Comparisons', 'less_than_minimum'),
        'logical/rule10': ('Comparisons', 'max_gt_second'),
        'logical/rule11': ('Comparisons', 'max_gt_first'),
        'clamp/rule01': ('Comparisons', 'clamp_idempotent'),
        'clamp/rule02': ('Comparisons', 'clamp_max_min'),
        'clamp/rule03': ('Comparisons', 'clamp_min_max'),
        'select/rule01': ('Select', 'equal'),
        'select/rule02': ('Select', 'true_branch'),
        'select/rule03': ('Select', 'false_branch'),
        'select/rule04': ('Select', 'negate_condition'),
        'reverse/rule01': ('Reverse', 'unit_axes'),
        'reverse/rule02': ('Reverse', 'involution'),
        'reverse/rule03': ('Reverse', 'overlapping_groups'),
        'reverse/rule04': ('Reverse', 'add_constant'),
        'concat/rule01': ('Concatenate', 'list_pair'),
        'concat/rule02': ('Concatenate', 'associate'),
        'concat/rule03': ('Concatenate', 'list_three'),
        'concat/rule04': ('Concatenate', 'touching_slices'),
        'concat/rule05': ('Concatenate', 'pad_low'),
        'concat/rule06': ('Concatenate', 'pad_high'),
        'concat/rule07': ('Concatenate', 'list_three_reverse'),
        'slice/rule08': ('Concatenate', 'slice_second'),
        'slice/rule10': ('Concatenate', 'slice_first_piece'),
        'slice/rule11': ('Concatenate', 'slice_second_piece'),
        'divmod/rule00': ('Numerical', 'divide_one_both'),
        'divmod/rule01': ('Numerical', 'divide_constant_real'),
        'divmod/rule02': ('Numerical', 'divide_fractions_real'),
        'divmod/rule03': ('Numerical', 'divide_nested_real'),
        'mul/rule09': ('Numerical', 'abs_square'),
        'mul/rule10': ('Numerical', 'exp_product_real'),
        'iota/rule01': ('Iota', 'unit_axis'),
        'broadcast/rule07': ('Iota', 'broadcast'),
        'broadcast/rule08': ('Iota', 'broadcast_composition'),
        'slice/rule03': ('SliceBroadcast', 'commute'),
        'slice/rule04': ('InteriorSlice', 'slice_occupied'),
        'slice/rule06': ('PadSlice', 'slice_after_pad'),
        'slice/rule09': ('SliceBroadcast', 'full_retained'),
        'slice/rule01': ('SliceGeometry', 'full'),
        'slice/rule07': ('SliceGeometry', 'nested'),
        'slice/rule02': ('Slices', 'slice_constant'),
        'broadcast/rule05': ('Slices', 'slice_constant'),
        'broadcast/rule06': ('Slices', 'dynamic_slice_constant'),
        'max/rule01': ('Extremes', 'max_negative_infinity'),
        'max/rule02': ('Extremes', 'min_positive_infinity'),
        'pad/rule01': ('Pad', 'identity'),
        'dot/rule01': ('GroupedSums', 'dot_concat'),
        'dot/rule02': ('GroupedSums', 'dot_swap'),
        'reduce/rule04': ('GroupedSums', 'relabel_reduce'),
        'reduce/rule06': ('GroupedSums', 'reduce_dot'),
        'dot/rule03': ('GroupedSums', 'dot_associativity'),
        'dot/rule06': ('GroupedSums', 'dot_no_right'),
        'reduce/rule01': ('GroupedSums', 'reduce_product'),
        'reduce/rule05': ('GroupedSums', 'reduce_nested'),
        'dot/rule04': ('Dot', 'no_contract'),
        'dot/rule05': ('Dot', 'empty_dimension'),
        'reduce/rule03': ('Reduction', 'scalar_factor'),
        'reduce/rule07': ('Reduction', 'singleton_reshape'),
        'reduce/rule08': ('Reduction', 'relabel_singleton_reshape'),
        'dyslice/rule01': ('Dynamic', 'static_slice'),
        'dyslice/rule02': ('Dynamic', 'full_slice'),
        'dyslice/rule03': ('SliceBroadcast', 'dynamic_commute'),
        'dyslice/rule04': ('Dynamic', 'relabel_slice'),
        'dyslice/rule05': ('Dynamic', 'nested_slice'),
        'dyupslice/rule01': ('Dynamic', 'add_into_update'),
        'dyupslice/rule02': ('UpdatePad', 'update_eq_pad'),
        'dyupslice/rule03': ('Dynamic', 'full_update'),
        'dyupslice/rule04': ('Dynamic', 'nested_update'),
        'relabel/rule01': ('Relabel', 'compose'),
        'relabel/rule02': ('Relabel', 'identity'),
        'broadcast/rule03': ('Relabel', 'uniform'),
        'divmod/rule04': ('Remainder', 'nested'),
        'divmod/rule05': ('Remainder', 'bounded_iota'),
        'divmod/rule06': ('Remainder', 'shifted_iota'),
        'divmod/rule07': ('Remainder', 'shifted_scalar'),
    })
    refutations = {'slice/rule13': ('ReverseSliceFailure', 'rhs_invalid')}
    witness_support = {'slice/rule13': ('ReverseSliceFailure', 'lhs_valid')}
    rerun = json.loads(RERUN.read_text())
    rerun_cases = {r['id']: r for r in rerun['cases']}
    assert len(rerun_cases) == 118 and set(rerun_cases) == {r['id'] for r in cases}
    triage = json.loads(TRIAGE.read_text())
    assert triage['schema'] == 1
    assert set(triage['cases']) == {r['id'] for r in cases} - set(proofs) - set(refutations)
    logs = {'Add': 'add-check.log', 'ScalarArithmetic': 'scalar-check.log',
            'Broadcast': 'broadcast-check.log', 'Logical': 'logical-check.log',
            'Comparisons': 'comparisons-check.log', 'Select': 'select-check.log',
            'Reverse': 'reverse-check.log', 'Concatenate': 'concatenate-check.log',
            'Numerical': 'numerical-check.log', 'Iota': 'iota-check.log',
            'Slices': 'slices-check.log', 'Extremes': 'extremes-check.log',
            'Dynamic': 'dynamic-check.log', 'Relabel': 'relabel-check.log',
            'Remainder': 'remainder-check.log',
            'SliceGeometry': 'slice-geometry-check.log', 'Dot': 'dot-check.log',
            'Reduction': 'reduction-check.log', 'Pad': 'pad-check.log',
            'ReverseSliceFailure': 'reverse-slice-failure-check.log',
            'SliceBroadcast': 'slice-broadcast-check.log',
            'UpdatePad': 'update-pad-check.log', 'PadSlice': 'pad-slice-check.log',
            'InteriorSlice': 'interior-slice-check.log',
            'GroupedSums': 'grouped-sums-check.log'}
    shape_support = {'dot/rule01': ('GroupedSums', 'dot_coordinate_sum'),
                     'reduce/rule06': ('GroupedSums', 'dot_coordinate_sum'),
                     'dot/rule02': ('GroupedSums', 'dot_coordinate_sum'),
                     'dot/rule03': ('GroupedSums', 'dot_coordinate_sum'),
                     'dot/rule06': ('GroupedSums', 'dot_coordinate_sum'),
                     'reduce/rule01': ('GroupedSums', 'reduce_coordinate_sum'),
                     'reduce/rule05': ('GroupedSums', 'reduce_coordinate_sum'),
                     'slice/rule04': ('InteriorSlice', 'paper_pad_extent'),
                     'slice/rule06': ('PadSlice', 'translated_valid'),
                     'dyupslice/rule02': ('UpdatePad', 'paper_shape'),
                     'dyslice/rule03': ('SliceBroadcast', 'dynamic_start'),
                     'slice/rule03': ('SliceBroadcast', 'retained_size'),
                     'slice/rule09': ('SliceBroadcast', 'retained_size'),
                     'dyslice/rule04': ('Dynamic', 'unclamped'),
                     'slice/rule10': ('Concatenate', 'paper_interval'),
                     'slice/rule11': ('Concatenate', 'paper_offset'),
                     'dot/rule05': ('Dot', 'grouped_empty'),
                     'reduce/rule07': ('Reduction', 'singleton_count'),
                     'reduce/rule08': ('Reduction', 'singleton_count'),
                     'slice/rule01': ('SliceGeometry', 'full_shape'),
                     'slice/rule07': ('SliceGeometry', 'nested_count'),
                     'slice/rule02': ('Slices', 'count_euclidean'),
                     'broadcast/rule05': ('Slices', 'count_exact'),
                     'dyslice/rule01': ('Dynamic', 'static_start'),
                     'dyslice/rule05': ('Dynamic', 'compose_eq_added'),
                     'dyupslice/rule04': ('Dynamic', 'compose_eq_added'),
                     'divmod/rule06': ('Remainder', 'signed_shift'),
                     'divmod/rule07': ('Remainder', 'signed_shift')}
    extra_support = {'dot/rule01': ('GroupedSums', 'concat_pair_coordinate'),
                     'reduce/rule06': ('GroupedSums', 'reduce_coordinate_sum'),
                     'dot/rule02': ('GroupedSums', 'sum_coordinate_groups'),
                     'dot/rule03': ('GroupedSums', 'sum_coordinate_groups'),
                     'dot/rule06': ('GroupedSums', 'sum_coordinate_groups'),
                     'reduce/rule01': ('GroupedSums', 'sum_coordinate_groups'),
                     'reduce/rule05': ('GroupedSums', 'sum_coordinate_groups'),
                     'slice/rule11': ('Concatenate', 'paper_interval'),
                     'slice/rule03': ('Slices', 'count_euclidean'),
                     'slice/rule09': ('SliceBroadcast', 'paper_ceil_count')}
    additional_support = {'reduce/rule06': ('GroupedSums', 'sum_coordinate_groups')}
    audited = (list(proofs.items()) + list(refutations.items()) + list(witness_support.items()) +
               list(shape_support.items()) + list(extra_support.items()) +
               list(additional_support.items()))
    for group, filename in logs.items():
        check = (OUT / filename).read_text()
        for key, (namespace, name) in audited:
            if namespace == group:
                prefix = f"'TensorRewrite.PaperComparison.{namespace}.{name}' "
                matches = list(re.finditer(re.escape(prefix) +
                    r'(does not depend on any axioms|depends on axioms: \[([^]]*)\])', check))
                assert len(matches) == 1, key
                detail = matches[0].group(2)
                if detail is not None:
                    axioms = {a.strip() for a in detail.split(',') if a.strip()}
                    assert axioms <= {'propext', 'Quot.sound', 'Classical.choice'}, (key, axioms)
    rows = []
    for index, (case, block) in enumerate(zip(cases, blocks)):
        lines = (ROOT / case['path']).read_text().splitlines()
        start = case['line'] - 1
        end = next((i for i in range(start + 1, len(lines))
                    if re.match(r'^\w+\s*::', lines[i])), len(lines))
        declaration = '\n'.join(lines[start:end]).rstrip() + '\n'
        label = block.splitlines()[0]
        if case['label'] and case['id'] != 'reduce/rule03':
            assert case['label'] == label, (case['id'], case['label'], label)
        status = re.findall(r'^\[(SUCCESS|FAIL)(?:-Overall)?\]:', block, re.M)
        assert status, case['id']
        types = re.findall(r'^>>> (Bool|Int|Real)$', block, re.M)
        row = {
            'id': case['id'], 'source_path': case['path'], 'source_line': case['line'],
            'source_sha256': digest((ROOT / case['path']).read_bytes()),
            'rule_declaration': declaration,
            'declaration_sha256': digest(declaration.encode()),
            'invocation': case['verifier_invocations'], 'reported_label': label,
            'archived_result': 'proved' if status[-1] == 'SUCCESS' else 'timeout_or_solver_failure',
            'archived_result_block_sha256': digest(block.encode()),
            'archived_result_types': types or ['see declaration and result block'],
            'independent_rerun_result': rerun_cases[case['id']]['outcome'],
            'lean_result': 'not_attempted_in_comparison', 'lean_theorems': [],
            'translation_confidence': 'not assessed',
            'implementation_result': 'not established',
        }
        assert row['independent_rerun_result'] == row['archived_result'], case['id']
        if case['id'] in triage['cases']:
            row['lean_result'] = 'unresolved'
            row['unresolved_reason'] = triage['cases'][case['id']]
            row['assessment_method'] = ('Paper declaration and existing proof dependencies '
                                        'reviewed; no timed proof attempt claimed by this triage.')
        if case['id'] in refutations:
            namespace, name = refutations[case['id']]
            assert types == ['Bool', 'Int', 'Real'], case['id']
            row.update(
                lean_result='disproved_in_model', lean_types=types,
                lean_theorems=[f'TensorRewrite.PaperComparison.{namespace}.lhs_valid',
                               f'TensorRewrite.PaperComparison.{namespace}.{name}'],
                lean_proof_file=f'comparisons/tensorright-v1/{namespace}.lean',
                lean_proof_sha256=digest((OUT / f'{namespace}.lean').read_bytes()),
                lean_check_log=f'comparisons/tensorright-v1/{logs[namespace]}',
                model_witness_log='comparisons/tensorright-v1/reverse-slice-witness.stdout',
                model_witness_patch='comparisons/tensorright-v1/reverse-slice-witness.patch',
                model_witness=('One axis of extent 10; lhs Slice start 2, limit 8, stride 2, '
                               'output length 3. The paper formulas require rhs start -3 and '
                               'limit 3. The lhs and its index 0 are valid; the rhs Slice '
                               'violates the required nonnegative start.'),
                translation_confidence=('The Lean definitions reproduce the paper rule13 '
                                        'count, start and end equations; for this positive '
                                        'stride they use the same div/mod convention. '
                                        'The artifact Slice requires nonnegative start. The fixed-input '
                                        'TensorRight diagnostic independently reports lhs valid '
                                        'and rhs invalid. No XLA conclusion is drawn.'))
        if case['id'] == 'dot/rule03':
            assert re.search(r'rewrite \"Dot\(A,Dot\(B,C\)\).*\" lhs lhs', declaration)
            row['benchmark_discrepancy'] = (
                'The label names Dot associativity and a rhs is constructed, but the '
                'artifact calls rewrite with lhs as both arguments. The archived success '
                'does not establish the labeled associativity statement.')
        if case['id'] in proofs:
            namespace, name = proofs[case['id']]
            if namespace == 'GroupedSums':
                confidence = ('The named disjoint axis groups are represented by arbitrary '
                              'bounded coordinate types. The support lemmas connect exact '
                              'group sums to actual Dot and Reduce coordinate enumeration '
                              'and construct an equivalence for combined groups. Operand '
                              'ordering follows the paper rule; C++ correspondence is assumed. '
                              'For dot/rule03 Lean proves the intended associativity; the '
                              'artifact itself verified lhs against lhs.')
            elif namespace == 'InteriorSlice':
                confidence = ('The nonnegative edge/interior Pad uses actual occupied '
                              'lattice coordinates, with spacing equal to interior+1; '
                              'paper_pad_extent derives the paper shape, including zero '
                              'input extent. The Slice uses the paper start, stride and '
                              'inferred input-sized output. C++ correspondence is assumed.')
            elif namespace == 'PadSlice':
                confidence = ('The paper assumes nonnegative edge padding, zero interior '
                              'padding and unit Slice stride. Its start/end bounds imply '
                              'the Slice lies inside the input region; translated_valid '
                              'derives the shifted Slice validity and matching output size. '
                              'All bounded coordinates are checked. C++ correspondence is assumed.')
            elif namespace == 'UpdatePad':
                confidence = ('The actual Pad and DynamicUpdateSlice models agree on '
                              'every bounded coordinate, including empty shapes. Paper low '
                              'and high padding are nonnegative, interior padding is zero, '
                              'and start equals low; paper_shape derives the stated output '
                              'shape. C++ correspondence is assumed, not checked.')
            elif namespace == 'SliceBroadcast' and name == 'dynamic_commute':
                confidence = ('Actual DynamicSlice and Broadcast projections commute on '
                              'retained axes with matching shape and start maps. The support '
                              'lemma proves the existing clamp is identity under the paper '
                              'valid in-bounds starts, including added axes. C++ correspondence '
                              'is assumed, not checked.')
            elif namespace == 'SliceBroadcast':
                confidence = ('Actual bounded Slice and Broadcast maps commute on each '
                              'retained axis. Matching paper start/end/stride attributes '
                              'derive the retained output sizes; the added Broadcast axes '
                              'use the paper count formulas, proved by the listed support '
                              'lemmas. C++ correspondence is assumed, not checked.')
            elif namespace == 'Pad':
                confidence = ('Zero low, high and interior padding is the edge-Pad model '
                              'with zero edges on every axis. The frame covers any nonempty '
                              'axis group and all extents; tensor shape transport and all '
                              'coordinates are explicit. C++ correspondence is assumed.')
            elif namespace == 'Dot' and name == 'empty_dimension':
                confidence = ('The nonempty paper aggregated-axis groups contribute '
                              'batch/free output or contraction axes. The zero-map guard '
                              'implies a zero dimension in one of those groups; grouped_empty '
                              'derives the corresponding output or contraction dimension. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Dot':
                confidence = ('The contraction plan models all batch, free and contracted '
                              'coordinates; with no contracted axes its outerTensor reads the '
                              'two projected operand coordinates and multiplies them, matching '
                              'the paper broadcast product. C++ correspondence is assumed.')
            elif namespace == 'Reduction' and name != 'scalar_factor':
                confidence = ('Every reduced axis has extent one, as in the paper; '
                              'the existing coordinate lemma connects unit-axis removal '
                              'with the reshape, including empty tensors. For rule08 the '
                              'label change is represented by the identity axis mapping; '
                              'it is removed by the subsequent reduction. C++ correspondence '
                              'is assumed, not checked.')
            elif namespace == 'Reduction':
                confidence = ('The additive reduction traverses all bounded reduced coordinates '
                              'with zero initializer. Multiplication by the paper scalar constant '
                              'distributes over the exact sum, including an empty fiber. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'SliceGeometry':
                confidence = ('The bounded Slice indices use the paper unit strides and exact '
                              'starts, including summed starts for nesting; companion theorems '
                              'derive inferred output sizes from the actual end bounds. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Remainder':
                confidence = ('Finite TensorInt uses Grisette remOr with dividend as the zero '
                              'divisor default; the pinned Grisette revision specifies Haskell '
                              'rem, matching Lean truncating remainder. Iota coordinates and '
                              'paper bounds or sign guards are explicit. C++ correspondence '
                              'is assumed, not checked.')
            elif namespace == 'Relabel':
                confidence = ('Relabel preserves axis extents and values; the bounded bijective '
                              'axis mapping models a more general permutation and covers the '
                              'paper label renamings. C++ correspondence is assumed, not checked.')
            elif namespace == 'Dynamic' and name == 'relabel_slice':
                confidence = ('The paper renames one label without reordering axis values; '
                              'the identity axis map captures that operation. Both sides use '
                              'the same slice window and start; the unclamped lemma connects '
                              'it to the paper valid-input semantics. C++ correspondence is assumed.')
            elif namespace == 'Dynamic':
                confidence = ('The paper requires in-bounds dynamic starts; the auxiliary '
                              'unclamped theorem proves the existing clamped model uses exactly '
                              'those starts. Nested windows derive the sum of the actual valid '
                              'starts; Add preserves the paper operand order by commutativity. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Extremes':
                confidence = ('The paper input tensor has finite numeric values; the explicit '
                              'negative or positive infinity constant is represented by WithBot '
                              'or WithTop. The relevant Min/Max branch returns the finite value. '
                              'This is not a full TensorNum or IEEE infinity semantics. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Slices':
                confidence = ('The paper’s Slice output size is represented by the inferred '
                              'valid shape; companion count lemmas connect Euclidean division '
                              'and exact stride lengths to that shape. The direct DynamicSlice '
                              'uses the paper in-bounds start conditions. C++ correspondence '
                              'is assumed, not checked.')
            elif namespace == 'Iota':
                confidence = ('Iota reads the bounded integer coordinate and Broadcast uses '
                              'actual composed signed axis maps. Paper Iota returns TensorInt; '
                              'composition preserves all data types and extents. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Numerical':
                confidence = ('Lean preserves the paper finite real/integer graph. Real division '
                              'uses the same zero-denominator default of zero; integer division '
                              'is used only by one. Exponential is exact real, not IEEE floating '
                              'point. C++ correspondence is assumed, not checked.')
            elif namespace == 'Concatenate' and name in {'slice_first_piece', 'slice_second_piece'}:
                confidence = ('The valid unit-stride paper Slice has length end minus start; '
                              'paper_interval derives this, and paper_offset derives the '
                              'second-operand offset. The frame has the single concrete '
                              'concat axis required by the artifact and preserves the other '
                              'dimensions. C++ correspondence is assumed, not checked.')
            elif namespace == 'Concatenate':
                confidence = ('Actual bounded Concat coordinates, shapes and relevant Slice/Pad '
                              'operators model the paper graph. Recursive list Concat follows '
                              'the artifact definition; unit-stride Slice adjacency is derived '
                              'from validity and touching limits. C++ correspondence is assumed.')
            elif namespace == 'Comparisons':
                confidence = ('The Lean graph uses finite exact linear-order values and the '
                              'paper comparisons, Min/Max and Clamp. Clamp operand order is '
                              'explicitly related using min commutativity; the bound premise '
                              'for clamp/rule02 matches its strict paper assumption. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Select':
                confidence = ('Lean uses the same elementwise Select semantics over arbitrary '
                              'values and conditions, including the paper constant condition. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Reverse':
                confidence = ('Lean reverses actual bounded coordinates, with unit extents or '
                              'disjoint axis groups corresponding to the paper conditions. '
                              'C++ correspondence is assumed, not checked.')
            elif namespace == 'Logical':
                confidence = ('The Lean theorem evaluates the same Boolean tensor operation '
                              'or exact numeric double negation on arbitrary finite shapes. '
                              'The data type is taken from the artifact declaration when the '
                              'archived log has no type label. C++ correspondence is assumed.')
            else:
                confidence = ('The Lean theorem uses actual bounded Broadcast coordinate projections '
                          'and the paper operators in the same order; the reverse rule is generic '
                          'over values. C++ correspondence is assumed, not checked.' if namespace == 'Broadcast' else
                          'Artifact original and replacement use same-shape elementwise exact '
                          'arithmetic; Lean proves the same identity for arbitrary tensors over '
                          'every commutative ring. Paper ordinary input tensors and constants '
                          'here are finite integer/real values. C++ correspondence is assumed, not checked.')
            row.update(lean_result='proved',
                       lean_theorems=[f'TensorRewrite.PaperComparison.{namespace}.{name}'],
                       translation_confidence=confidence,
                       lean_types=(['Bool', 'Int', 'Real'] if namespace in {'Concatenate', 'Relabel', 'SliceGeometry', 'SliceBroadcast', 'UpdatePad', 'PadSlice', 'InteriorSlice', 'Pad'} or case['id'] in {
                                       'broadcast/rule04', 'select/rule01', 'select/rule02',
                                       'select/rule03', 'select/rule04', 'reverse/rule01',
                                       'reverse/rule02', 'reverse/rule03', 'broadcast/rule08',
                                       'slice/rule02', 'broadcast/rule05', 'broadcast/rule06',
                                       'dyslice/rule01', 'dyslice/rule02', 'dyslice/rule04', 'dyslice/rule05',
                                       'dyupslice/rule03', 'dyupslice/rule04'}
                                   else ['Int'] if namespace == 'Remainder' or case['id'] in {
                                       'iota/rule01', 'broadcast/rule07'}
                                   else ['Bool'] if namespace == 'Logical' and name != 'neg_neg'
                                   else ['Real'] if case['id'] in {'divmod/rule01',
                                       'divmod/rule02', 'divmod/rule03', 'mul/rule10'}
                                   else ['Int', 'Real']),
                       lean_proof_file=f'comparisons/tensorright-v1/{namespace}.lean',
                       lean_proof_sha256=digest((OUT / f'{namespace}.lean').read_bytes()),
                       lean_check_log=f'comparisons/tensorright-v1/{logs[namespace]}')
            if case['id'] in shape_support:
                support_namespace, support_name = shape_support[case['id']]
                row['lean_support_theorems'] = [
                    f'TensorRewrite.PaperComparison.{support_namespace}.{support_name}']
            if case['id'] in extra_support:
                support_namespace, support_name = extra_support[case['id']]
                row.setdefault('lean_support_theorems', []).append(
                    f'TensorRewrite.PaperComparison.{support_namespace}.{support_name}')
            if case['id'] in additional_support:
                support_namespace, support_name = additional_support[case['id']]
                row.setdefault('lean_support_theorems', []).append(
                    f'TensorRewrite.PaperComparison.{support_namespace}.{support_name}')
            if types:
                assert set(row['lean_types']) == set(types), case['id']
            else:
                if row['lean_types'] == ['Bool']:
                    assert '@SymBool' in declaration, case['id']
                elif row['lean_types'] == ['Real']:
                    assert '@TensorReal' in declaration, case['id']
                elif row['lean_types'] == ['Int']:
                    assert ('iota ' in declaration or '@TensorInt' in declaration
                            or ':: TensorInt' in declaration), case['id']
                else:
                    raise AssertionError((case['id'], row['lean_types']))
                row['archived_result_types'] = row['lean_types']
                row['type_provenance'] = ('artifact rule declaration or Iota constructor signature; '
                                          'archived result has no type label')
        rows.append(row)
    assert Counter(r['archived_result'] for r in rows) == {'proved': 115, 'timeout_or_solver_failure': 3}
    result = {'schema': 1, 'scope': '118 executed paper-era model cases, not verified C++',
              'inventory_sha256': digest(INVENTORY.read_bytes()),
              'archived_result_sha256': digest(RESULT.read_bytes()),
              'unresolved_triage_sha256': digest(TRIAGE.read_bytes()),
              'independent_rerun_sha256': digest(RERUN.read_bytes()),
              'archived_result_provenance': 'author-provided result.txt; independent rerun recorded separately',
              'matching': 'runall sorted directories and main call order; printed labels checked except known shell expansion',
              'counts': {'cases': len(rows), 'paper_proved': 115, 'paper_failed': 3,
                         'lean_proved': sum(r['lean_result'] == 'proved' for r in rows),
                         'lean_disproved_in_model': sum(
                             r['lean_result'] == 'disproved_in_model' for r in rows),
                         'lean_unresolved': sum(r['lean_result'] == 'unresolved' for r in rows),
                         'lean_proved_paper_failed': sum(
                             r['lean_result'] == 'proved' and
                             r['archived_result'] == 'timeout_or_solver_failure' for r in rows)},
              'cases': rows}
    (OUT / 'cases.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    table = ['# TensorRight paper-era comparison', '',
             'Archived paper outcomes are author-reported; Lean results are this project’s.',
             'See cases.json for exact source declarations, types, hashes and scope.',
             'Unresolved reasons identify missing proof connections; triage alone is not a timed proof attempt.', '',
             '| Case | Paper archive | TensorRight rerun | Lean |', '| --- | --- | --- | --- |']
    table.extend(f"| {r['id']} | {r['archived_result']} | {r['independent_rerun_result']} | "
                 f"{r['lean_result']} |" for r in rows)
    table.extend(['', '**Benchmark caveat:** `dot/rule03` is labeled as Dot associativity, '
                  'but the artifact passes `lhs` as both sides to the verifier. Its archived '
                  'success does not verify the labeled rewrite.'])
    (OUT / 'cases.md').write_text('\n'.join(table) + '\n')
    residuals = ['# Unresolved paper cases', '', triage['method'], '',
                 '| Case | Archived result | Missing connection |', '| --- | --- | --- |']
    residuals.extend(f"| {r['id']} | {r['archived_result']} | {r['unresolved_reason']} |"
                     for r in rows if r['lean_result'] == 'unresolved')
    (OUT / 'triage.md').write_text('\n'.join(residuals) + '\n')
    print(result['counts'])


if __name__ == '__main__':
    main()
