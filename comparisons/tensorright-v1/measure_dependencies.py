"""Measure custom Lean source in each comparison module's transitive import closure.

This is an import-based upper bound, not a minimal proof or fresh-agent effort.
Whole source modules count, even if a particular theorem uses only one declaration.
Mathlib, Lean/Std, FloatLib, generated artifacts, and non-Lean source are excluded.
"""
import hashlib
import importlib.util
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('lean_size', ROOT / 'tools/lean_size.py')
lean_size = importlib.util.module_from_spec(spec)
spec.loader.exec_module(lean_size)
IMPORT = re.compile(r'^\s*(?:public\s+)?import\s+([^\n]+)', re.MULTILINE)


def imports(path):
    for line in IMPORT.findall(path.read_text()):
        for module in line.split('--', 1)[0].split():
            if module == 'TensorRewrite' or module.startswith('TensorRewrite.'):
                relative = Path(*module.split('.')).with_suffix('.lean')
                target = ROOT / relative
                if not target.is_file():
                    raise ValueError(f'Cannot find local import {module} from {path}')
                yield target


def closure(path):
    seen, pending = set(), [path]
    while pending:
        current = pending.pop()
        if current not in seen:
            seen.add(current)
            pending.extend(imports(current))
    return seen


def category(path):
    relative = path.relative_to(ROOT)
    if relative.parts[:2] == ('TensorRewrite', 'Pilot'):
        return 'pilot'
    if relative.parts[:2] == ('TensorRewrite', 'Theory'):
        return 'theory'
    if relative.parts[0] == 'comparisons':
        return 'comparison'
    return 'other_custom'


def main():
    modules = sorted(OUT.glob('*.lean'))
    cases = json.loads((OUT / 'cases.json').read_text())
    resolved = [row for row in cases['cases'] if row['lean_result'] in
                {'proved', 'disproved_in_model', 'vacuous_in_paper_model'}]
    expected = {ROOT / row['lean_proof_file'] for row in resolved}
    assert expected == set(modules), 'Every counted comparison module must have a credited case'
    closures = {p: closure(p) for p in modules}
    union = set().union(*closures.values())
    sizes = {p: lean_size.count_source(p.read_text())['code_lines'] for p in union}
    groups = {key: sum(sizes[p] for p in union if category(p) == key)
              for key in ['comparison', 'pilot', 'theory', 'other_custom']}
    report = {
        'schema': 1,
        'method': 'Whole-module transitive custom Lean imports; excludes external libraries. '
                  'Shared modules count once in the union. Per-case values overlap and are '
                  'not additive or minimal; no claim of fresh-agent production cost.',
        'counter': 'tools/lean_size.py, counter_version 1',
        'counts': {'custom_module_count': len(union), 'custom_code_lines': sum(sizes.values()),
                   'by_location': groups},
        'files': [{'path': str(p.relative_to(ROOT)), 'category': category(p),
                   'code_lines': sizes[p], 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                  for p in sorted(union)],
        'cases': [{'id': row['id'], 'comparison_module': row['lean_proof_file'],
                   'result': row['lean_result'],
                   'closure_modules': len(closures[ROOT / row['lean_proof_file']]),
                   'closure_code_lines': sum(sizes[p] for p in closures[ROOT / row['lean_proof_file']])}
                  for row in resolved],
    }
    (OUT / 'dependency-costs.json').write_text(json.dumps(report, indent=2) + '\n')
    print(report['counts'])


if __name__ == '__main__':
    main()
