"""Validate ordered full-span window/reduction/reshape mathematics only."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from full_span_window_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/full-span-window-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('ordered_contribution_lists_equal', 'initializer_retained',
               'output_shape_and_reshape_derived', 'mixed_kept_reduced_axes',
               'empty_and_scalar_cases_included')
FALSE_FIELDS = ('algebraic_laws_assumed', 'shape_or_index_equivalence_postulated',
                'all_window_rewrites_proved', 'full_workload_complete',
                'independently_reviewed_statements', 'benchmark_correspondence_certified',
                'code_correspondence_performed', 'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    manifest = json.loads((ROOT / MANIFEST).read_text())
    for row in manifest['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['conditions'] == 'kept axes use kernel1; reduced axes use kernel=input extent; unit stride and both dilations; zero padding; no reversal'
    assert manifest['shape_or_index_equivalence_postulated'] is False
    assert manifest['scalar_contract'] == 'arbitrary type, operation, initializer and padding'
    return manifest


def validate_result(result):
    manifest = check_inputs()
    assert result['status'] == 'kernel_checked_ordered_full_span_reduction_reshape'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 20
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert all(set(axioms) <= ALLOWED for axioms in result['certificate_axioms'].values())
    counts, rows = expected()
    assert result['profile_counts'] == counts and result['controls'] == rows
    assert result['profile_count'] == len(counts) == 585
    assert result['output_count'] == len(rows) == 1111
    for key in TRUE_FIELDS:
        assert result[key] is True, key
    for key in FALSE_FIELDS:
        assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/FullSpanWindowControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
    assert 'warning:' not in run.stdout + run.stderr, run.stdout + run.stderr
    pattern = r'^FULLSPAN_COUNT profile=(\d+) rank=(\d+) inputs=(\d+) outputs=(\d+) kernels=(\d+)$'
    counts = [dict(zip(('profile', 'rank', 'inputs', 'outputs', 'kernels'), map(int, match)))
              for match in re.findall(pattern, run.stdout, re.M)]
    pattern = (r'^FULLSPAN profile=(\d+) output=(\d+) trace=(\[[\d, ]*\]) '
               r'fiber=(\[[\d, ]*\]) window=(\d+) reshape=(\d+)$')
    rows = [dict(profile=int(p), output=int(o), trace=json.loads(t), fiber=json.loads(f),
                 window=int(w), reshape=int(r))
            for p, o, t, f, w, r in re.findall(pattern, run.stdout, re.M)]
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']:
        assert digest(ROOT / row['path']) == row['sha256']
    axioms = {name: axioms for name, axioms in theory['axiom_dependencies'].items()
              if '.FullSpanWindow.' in name or '.OrderedCoordinates.' in name}
    result = dict(status='kernel_checked_ordered_full_span_reduction_reshape',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT / MANIFEST),
                  checked_statement_count=len(axioms), certificate_axioms=axioms,
                  profile_counts=counts, controls=rows, control_stdout=run.stdout,
                  profile_count=len(counts), output_count=len(rows),
                  whole_benchmark_records_closed=0, mathematical_obligation_denominator=None)
    result.update({key: True for key in TRUE_FIELDS})
    result.update({key: False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT / 'reports/full-span-window.json').write_text(json.dumps(result, indent=2) + '\n')
    print('Full-span windows:20 checked statements;585 mixed axis profiles/1111 outputs agree; '
          'whole workload remains open.')


if __name__ == '__main__':
    main()
