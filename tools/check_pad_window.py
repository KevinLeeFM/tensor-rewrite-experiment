"""Check independent Pad/window composition and its converted-fill contract, mathematics only."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from pad_window_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/pad-window-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('independent_pad_operator', 'empty_safe_geometry_derived',
               'ordered_contribution_lists_equal', 'initializer_retained',
               'converted_fill_retained', 'same_explicit_implicit_fill_required')
FALSE_FIELDS = ('algebraic_laws_assumed', 'shape_or_index_equivalence_postulated',
                'all_window_rewrites_proved', 'full_workload_complete',
                'independently_reviewed_statements', 'benchmark_correspondence_certified',
                'code_correspondence_performed', 'broadcast_sequence_proved',
                'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    manifest = json.loads((ROOT / MANIFEST).read_text())
    for row in manifest['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['conditions'] == 'nonnegative Pad low/high; positive interior spacing; arbitrary positive window stride/dilations, signed window padding and reversal; same explicit and implicit fill'
    assert manifest['scalar_contract'] == 'arbitrary operation/initializer; pure heterogeneous conversion retains actual converted fill'
    assert manifest['shape_or_index_equivalence_postulated'] is False
    domains = json.loads((ROOT / manifest['window_domain_worksheet']).read_text())
    previous = json.loads((ROOT / domains['supersedes']['path']).read_text())
    assert digest(ROOT / domains['supersedes']['path']) == domains['supersedes']['sha256']
    assert {r['benchmark_id'] for r in domains['records']} == {
        r['benchmark_id'] for r in previous['records']}
    assert len(domains['records']) == 31
    assert sum(bool(r['core_evidence']) for r in domains['records']) == 22
    assert all(not r['whole_record_closed'] for r in domains['records'])
    return manifest


def validate_result(result):
    manifest = check_inputs()
    assert result['status'] == 'kernel_checked_ordered_pad_window_fusion'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 23
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert result['counterexample_certificates'] == manifest['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 2
    assert all(set(axioms) <= ALLOWED for axioms in result['certificate_axioms'].values())
    counts, rows = expected()
    assert result['profile_counts'] == counts and result['controls'] == rows
    assert result['profile_count'] == len(counts) == 655
    assert result['output_count'] == len(rows) == 3043
    for key in TRUE_FIELDS:
        assert result[key] is True, key
    for key in FALSE_FIELDS:
        assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    manifest = check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/PadWindowControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
    assert 'warning:' not in run.stdout + run.stderr, run.stdout + run.stderr
    pattern = (r'^PAD_COUNT profile=(\d+) rank=(\d+) inputs=(\d+) padded=(\d+) '
               r'outputs=(\d+) fused=(\d+) kernels=(\d+)$')
    counts = [dict(zip(('profile', 'rank', 'inputs', 'padded', 'outputs', 'fused', 'kernels'),
                       map(int, match))) for match in re.findall(pattern, run.stdout, re.M)]
    pattern = (r'^PAD profile=(\d+) output=(\d+) trace=(\[[-\d, ]*\]) '
               r'fused_trace=(\[[-\d, ]*\]) source=(-?\d+) target=(-?\d+) '
               r'bool_source=(true|false) bool_target=(true|false)$')
    rows = [dict(profile=int(p), output=int(o), trace=json.loads(t), fused_trace=json.loads(f),
                 source=int(s), target=int(v), bool_source=b == 'true', bool_target=c == 'true')
            for p, o, t, f, s, v, b, c in re.findall(pattern, run.stdout, re.M)]
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']:
        assert digest(ROOT / row['path']) == row['sha256']
    axioms = {name: axioms for name, axioms in theory['axiom_dependencies'].items()
              if '.PadWindow.' in name or '.LatticeIndex.' in name}
    result = dict(status='kernel_checked_ordered_pad_window_fusion',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT / MANIFEST),
                  checked_statement_count=len(axioms), certificate_axioms=axioms,
                  counterexample_certificates=manifest['counterexample_certificates'],
                  profile_counts=counts, controls=rows, control_stdout=run.stdout,
                  profile_count=len(counts), output_count=len(rows),
                  whole_benchmark_records_closed=0, mathematical_obligation_denominator=None)
    result.update({key: True for key in TRUE_FIELDS})
    result.update({key: False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT / 'reports/pad-window.json').write_text(json.dumps(result, indent=2) + '\n')
    print('Pad/window fusion:23 checked statements;655 profiles/3043 outputs agree; '
          'two mathematical contract refutations; whole workload remains open.')


if __name__ == '__main__':
    main()
