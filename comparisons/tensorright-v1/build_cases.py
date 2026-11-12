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
    })
    logs = {'Add': 'add-check.log', 'ScalarArithmetic': 'scalar-check.log',
            'Broadcast': 'broadcast-check.log', 'Logical': 'logical-check.log'}
    for group, filename in logs.items():
        check = (OUT / filename).read_text()
        for key, (namespace, name) in proofs.items():
            if namespace == group:
                prefix = f"'TensorRewrite.PaperComparison.{namespace}.{name}' "
                lines = [line for line in check.splitlines() if line.startswith(prefix)]
                assert len(lines) == 1, key
                assert lines[0][len(prefix):] in (
                    'depends on axioms: [propext, Quot.sound]',
                    'depends on axioms: [propext, Classical.choice, Quot.sound]',
                    'does not depend on any axioms'), (key, lines)
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
            if namespace == 'Logical':
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
                       lean_types=(['Bool', 'Int', 'Real'] if case['id'] == 'broadcast/rule04'
                                   else ['Bool'] if namespace == 'Logical' and name != 'neg_neg'
                                   else ['Int', 'Real']),
                       lean_proof_file=f'comparisons/tensorright-v1/{namespace}.lean',
                       lean_proof_sha256=digest((OUT / f'{namespace}.lean').read_bytes()),
                       lean_check_log=f'comparisons/tensorright-v1/{logs[namespace]}')
            if types:
                assert set(row['lean_types']) == set(types), case['id']
            else:
                assert row['lean_types'] == ['Bool'] and '@SymBool' in declaration, case['id']
                row['archived_result_types'] = ['Bool']
                row['type_provenance'] = 'artifact rule declaration; archived result has no type label'
        rows.append(row)
    assert Counter(r['archived_result'] for r in rows) == {'proved': 115, 'timeout_or_solver_failure': 3}
    result = {'schema': 1, 'scope': '118 executed paper-era model cases, not verified C++',
              'inventory_sha256': digest(INVENTORY.read_bytes()),
              'archived_result_sha256': digest(RESULT.read_bytes()),
              'archived_result_provenance': 'author-provided result.txt, not an independent rerun',
              'matching': 'runall sorted directories and main call order; printed labels checked except known shell expansion',
              'counts': {'cases': len(rows), 'paper_proved': 115, 'paper_failed': 3,
                         'lean_proved': sum(r['lean_result'] == 'proved' for r in rows)},
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
