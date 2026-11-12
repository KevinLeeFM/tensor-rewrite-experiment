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
        'divmod/rule00': ('Numerical', 'divide_one_both'),
        'divmod/rule01': ('Numerical', 'divide_constant_real'),
        'divmod/rule02': ('Numerical', 'divide_fractions_real'),
        'divmod/rule03': ('Numerical', 'divide_nested_real'),
        'mul/rule09': ('Numerical', 'abs_square'),
        'mul/rule10': ('Numerical', 'exp_product_real'),
        'iota/rule01': ('Iota', 'unit_axis'),
        'broadcast/rule07': ('Iota', 'broadcast'),
        'broadcast/rule08': ('Iota', 'broadcast_composition'),
        'slice/rule02': ('Slices', 'slice_constant'),
        'broadcast/rule05': ('Slices', 'slice_constant'),
        'broadcast/rule06': ('Slices', 'dynamic_slice_constant'),
        'max/rule01': ('Extremes', 'max_negative_infinity'),
        'max/rule02': ('Extremes', 'min_positive_infinity'),
        'dyslice/rule01': ('Dynamic', 'static_slice'),
        'dyslice/rule02': ('Dynamic', 'full_slice'),
        'dyslice/rule05': ('Dynamic', 'nested_slice'),
        'dyupslice/rule01': ('Dynamic', 'add_into_update'),
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
    logs = {'Add': 'add-check.log', 'ScalarArithmetic': 'scalar-check.log',
            'Broadcast': 'broadcast-check.log', 'Logical': 'logical-check.log',
            'Comparisons': 'comparisons-check.log', 'Select': 'select-check.log',
            'Reverse': 'reverse-check.log', 'Concatenate': 'concatenate-check.log',
            'Numerical': 'numerical-check.log', 'Iota': 'iota-check.log',
            'Slices': 'slices-check.log', 'Extremes': 'extremes-check.log',
            'Dynamic': 'dynamic-check.log', 'Relabel': 'relabel-check.log',
            'Remainder': 'remainder-check.log'}
    shape_support = {'slice/rule02': ('Slices', 'count_euclidean'),
                     'broadcast/rule05': ('Slices', 'count_exact'),
                     'dyslice/rule01': ('Dynamic', 'static_start'),
                     'dyslice/rule05': ('Dynamic', 'compose_eq_added'),
                     'dyupslice/rule04': ('Dynamic', 'compose_eq_added'),
                     'divmod/rule06': ('Remainder', 'signed_shift'),
                     'divmod/rule07': ('Remainder', 'signed_shift')}
    audited = list(proofs.items()) + list(shape_support.items())
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
            'lean_result': 'not_attempted_in_comparison', 'lean_theorems': [],
            'translation_confidence': 'not assessed',
            'implementation_result': 'not established',
        }
        if case['id'] in proofs:
            namespace, name = proofs[case['id']]
            if namespace == 'Remainder':
                confidence = ('Finite TensorInt uses Grisette remOr with dividend as the zero '
                              'divisor default; the pinned Grisette revision specifies Haskell '
                              'rem, matching Lean truncating remainder. Iota coordinates and '
                              'paper bounds or sign guards are explicit. C++ correspondence '
                              'is assumed, not checked.')
            elif namespace == 'Relabel':
                confidence = ('Relabel preserves axis extents and values; the bounded bijective '
                              'axis mapping models a more general permutation and covers the '
                              'paper label renamings. C++ correspondence is assumed, not checked.')
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
                       lean_types=(['Bool', 'Int', 'Real'] if namespace in {'Concatenate', 'Relabel'} or case['id'] in {
                                       'broadcast/rule04', 'select/rule01', 'select/rule02',
                                       'select/rule03', 'select/rule04', 'reverse/rule01',
                                       'reverse/rule02', 'reverse/rule03', 'broadcast/rule08',
                                       'slice/rule02', 'broadcast/rule05', 'broadcast/rule06',
                                       'dyslice/rule01', 'dyslice/rule02', 'dyslice/rule05',
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
              'archived_result_provenance': 'author-provided result.txt, not an independent rerun',
              'matching': 'runall sorted directories and main call order; printed labels checked except known shell expansion',
              'counts': {'cases': len(rows), 'paper_proved': 115, 'paper_failed': 3,
                         'lean_proved': sum(r['lean_result'] == 'proved' for r in rows),
                         'lean_proved_paper_failed': sum(
                             r['lean_result'] == 'proved' and
                             r['archived_result'] == 'timeout_or_solver_failure' for r in rows)},
              'cases': rows}
    (OUT / 'cases.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    table = ['# TensorRight paper-era comparison', '',
             'Archived paper outcomes are author-reported; Lean results are this project’s.',
             'See cases.json for exact source declarations, types, hashes and scope.', '',
             '| Case | Paper | Lean |', '| --- | --- | --- |']
    table.extend(f"| {r['id']} | {r['archived_result']} | {r['lean_result']} |" for r in rows)
    (OUT / 'cases.md').write_text('\n'.join(table) + '\n')
    print(result['counts'])


if __name__ == '__main__':
    main()
