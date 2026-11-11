"""Validate ordered prefix geometry, exact/modular products and conversion domains, math only."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from prefix_window_examples import expected

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/prefix-window-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
TRUE_FIELDS = ('direct_prefix_semantics', 'ordered_padding_prefix_partition',
               'initializer_fixed_point_required_for_prefix_only', 'retained_strides_general',
               'all_integer_widths', 'same_width_iota_product', 'signed_unsigned_exact_domains_iff',
               'empty_scan_included', 'worksheet_evidence_checked')
FALSE_FIELDS = ('rounded_uniform_sum_product_proved', 'intermediate_count_width_conversion_proved',
                'scalar_wrapper_recognition_proved', 'all_cumulative_rewrites_proved',
                'full_workload_complete', 'independently_reviewed_statements',
                'benchmark_correspondence_certified', 'code_correspondence_performed',
                'external_ir_admission_proved')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    manifest = json.loads((ROOT / MANIFEST).read_text())
    for row in manifest['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    assert digest(ROOT / 'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['conditions'] == 'one full-extent cumulative axis: unit stride/dilations, low=n-1 signed, high0, no reversal; other axes unit unpadded windows with arbitrary positive strides'
    assert manifest['arithmetic_contract'] == 'arbitrary folds retain leading padding; prefix-only needs op(initial,padding)=initial; exact AddMonoid/Semiring or same-width modular BitVec; count observation ranges iff'
    assert manifest['shape_or_sample_equivalence_postulated'] is False
    domains = json.loads((ROOT / manifest['window_domain_worksheet']).read_text())
    predecessor = domains['supersedes']
    assert digest(ROOT / predecessor['path']) == predecessor['sha256']
    previous = json.loads((ROOT / predecessor['path']).read_text())
    assert {r['benchmark_id'] for r in domains['records']} == {
        r['benchmark_id'] for r in previous['records']}
    assert len(domains['records']) == 31
    assert sum(bool(r['core_evidence']) for r in domains['records']) == 26
    assert all(not r['whole_record_closed'] for r in domains['records'])
    return manifest


def validate_result(result):
    manifest = check_inputs()
    assert result['status'] == 'kernel_checked_ordered_prefix_and_integer_count_domains'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 34
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert result['counterexample_certificates'] == manifest['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 3
    assert all(set(a) <= ALLOWED for a in result['certificate_axioms'].values())
    counts, rows, conversions = expected()
    assert result['profile_counts'] == counts and result['controls'] == rows
    assert result['conversion_controls'] == conversions
    assert result['profile_count'] == len(counts) == 726
    assert result['output_count'] == len(rows) == 1290
    assert result['conversion_count'] == len(conversions) == 45
    for key in TRUE_FIELDS:
        assert result[key] is True, key
    for key in FALSE_FIELDS:
        assert result[key] is False, key
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    manifest = check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/PrefixWindowControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout + run.stderr
    assert 'warning:' not in run.stdout + run.stderr, run.stdout + run.stderr
    pattern = (r'^PREFIX_COUNT profile=(\d+) rank=(\d+) scan=(\d+) inputs=(\d+) '
               r'outputs=(\d+) kernels=(\d+)$')
    counts = [dict(zip(('profile', 'rank', 'scan', 'inputs', 'outputs', 'kernels'), map(int, m)))
              for m in re.findall(pattern, run.stdout, re.M)]
    pattern = (r'^PREFIX profile=(\d+) output=(\d+) index=(\d+) padding=(\d+) trace=(\[[\d, ]*\]) '
               r'prefix=(\[[\d, ]*\]) source=(\d+) factor=(\d+) neutral=(\d+) prefix_fold=(\d+) '
               r'count=(\d+) product2=(\d+) product32=(\d+) product64=(\d+) count2u=(\d+) count2s=(-?\d+)$')
    keys = ('profile', 'output', 'index', 'padding', 'trace', 'prefix', 'source', 'factor',
            'neutral', 'prefix_fold', 'count', 'product2', 'product32', 'product64', 'count2u', 'count2s')
    rows = [{k: json.loads(v) if k in ('trace', 'prefix') else int(v) for k, v in zip(keys, m)}
            for m in re.findall(pattern, run.stdout, re.M)]
    conversions = [dict(zip(('width', 'count', 'unsigned', 'signed'), map(int, m))) for m in
                   re.findall(r'^PREFIX_CAST width=(\d+) count=(\d+) unsigned=(\d+) signed=(-?\d+)$',
                              run.stdout, re.M)]
    theory = json.loads((ROOT / 'reports/theory-progress.json').read_text())
    for row in theory['files']:
        assert digest(ROOT / row['path']) == row['sha256']
    domains = json.loads((ROOT / manifest['window_domain_worksheet']).read_text())
    assert {n for r in domains['records'] for n in r['core_evidence']} <= theory['axiom_dependencies'].keys()
    axioms = {n: a for n, a in theory['axiom_dependencies'].items() if '.PrefixWindow.' in n}
    result = dict(status='kernel_checked_ordered_prefix_and_integer_count_domains',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT / MANIFEST),
                  checked_statement_count=len(axioms), certificate_axioms=axioms,
                  counterexample_certificates=manifest['counterexample_certificates'],
                  profile_counts=counts, controls=rows, conversion_controls=conversions,
                  control_stdout=run.stdout, profile_count=len(counts), output_count=len(rows),
                  conversion_count=len(conversions), whole_benchmark_records_closed=0,
                  mathematical_obligation_denominator=None)
    result.update({key: True for key in TRUE_FIELDS})
    result.update({key: False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT / 'reports/prefix-window.json').write_text(json.dumps(result, indent=2) + '\n')
    print('Prefix windows:34 checked statements;726 profiles/1290 outputs and45 conversion '
          'controls agree; three mathematical contract certificates; whole workload remains open.')


if __name__ == '__main__':
    main()
