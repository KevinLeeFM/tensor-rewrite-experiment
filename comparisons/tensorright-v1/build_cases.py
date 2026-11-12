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
    result_text = RESULT.read_text()
    blocks = re.split(r'^====> ', result_text, flags=re.M)[1:]
    assert len(blocks) == len(cases)
    proof_names = ['reassociate', 'zero_right', 'zero_left', 'commute']
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
        if index < 4:
            assert case['id'] == f'add/rule0{index + 1}'
            row.update(lean_result='proved',
                       lean_theorems=['TensorRewrite.PaperComparison.Add.' + proof_names[index]],
                       translation_confidence=('Artifact original and replacement use same-shape '
                           'elementwise addition; Lean proves a stronger arbitrary-tensor version '
                           'over every commutative ring. Paper ordinary input tensors are finite '
                           'integer/real values; constants are a special case. C++ correspondence '
                           'is assumed, not checked.'),
                       lean_types=['Int', 'Real'],
                       lean_proof_file='comparisons/tensorright-v1/Add.lean')
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
