"""Replay the frozen exact-order family, real/word partitions and actual IEEE negative controls."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import order_examples as oracle

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/order-values-family-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
FALSE_FIELDS = ('floating_point_linear_order_assumed', 'floating_point_minmax_modeled',
                'runtime_id_encoding_bound_derived', 'full_workload_complete',
                'independently_reviewed_statements', 'benchmark_correspondence_certified',
                'source_guards_adopted_as_proof_assumptions', 'code_correspondence_performed')


def digest(path): return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def profile_units():
    return [dict(id=track+'/'+r['key'], track=track, rule=r['key'],
                 side_condition=r['condition'], shape='all finite ranks and extents, including empty')
            for track in oracle.TRACKS for r in oracle.rules()]


def check_inputs(root=ROOT):
    frozen = json.loads((root/MANIFEST).read_text())
    for row in frozen['files']:
        assert digest(root/row['path']) == row['sha256'], row['path']
    assert digest(root/'lake-manifest.json') == frozen['lake_manifest_sha256']
    assert frozen['family'] == 'typed_linear_order_values_v1'
    assert frozen['profile_units'] == profile_units() and frozen['profile_unit_count'] == 176
    assert frozen['rule_order_instance_count'] == 44
    assert len(frozen['certificates']) == 18 and len(frozen['counterexample_certificates']) == 4
    assert frozen['clamp_definition'] == 'min(max(value,lower),upper), including reversed bounds'
    assert frozen['zero_is_global_minimum_assumed'] is False
    assert frozen['signed_word_order'] == 'actual BitVec.toInt via injective lifted order'
    assert frozen['unsigned_word_order'] == 'actual BitVec.toNat via injective lifted order'
    assert frozen['candidate_benchmark_labels'] == sorted(set(
        label for labels in frozen['candidate_benchmark_bindings'].values() for label in labels))
    sheet = json.loads((root/frozen['domain_worksheet']).read_text())
    assert sorted(r['benchmark_id'] for r in sheet['records']) == frozen['candidate_benchmark_labels']
    for row in sheet['records']:
        assert row['whole_record_closed'] is False
        assert row['candidate_label_correspondence_certified'] is False
        assert row['remaining_partitions'] and row['mathematical_premises']
    return frozen


def validate_controls(stdout):
    assert not re.search(r'error(?:\(|:)|warning:', stdout), stdout[-3000:]
    trees, profiles, rows, ieee = [], [], [], []
    for line in stdout.splitlines():
        if line.startswith('ORDER_TREE '):
            m = re.fullmatch(r'ORDER_TREE key=(\w+) lhs=(.*?) \| rhs=(.*)', line)
            assert m, line
            trees.append((m[1], m[2], m[3]))
        elif line.startswith('ORDER_PROFILE '):
            m = re.fullmatch(r'ORDER_PROFILE track=(\w+) key=(\w+)', line)
            assert m, line
            profiles.append((m[1], m[2]))
        elif line.startswith('ORDER_ROW '):
            m = re.fullmatch(r'ORDER_ROW domain=(\w+) width=(\d+) sample=(\d+) raw=([\d,\-]+) decoded=([\d,\-]+) key=(\w+) admitted=(true|false) lhs=([vp]):(-?\d+) rhs=([vp]):(-?\d+)', line)
            assert m, line
            assert m[8] == m[10], line
            rows.append((m[1], int(m[2]), int(m[3]), tuple(map(int, m[4].split(','))),
                         tuple(map(int, m[5].split(','))), m[6], m[7] == 'true',
                         m[8], int(m[9]), int(m[11])))
        elif line.startswith('ORDER_IEEE '): ieee.append(line)
    assert trees == [(r['key'], r['lhs'], r['rhs']) for r in oracle.rules()]
    assert profiles == [(track, rule['key']) for rule in oracle.rules() for track in oracle.TRACKS]
    assert rows == list(oracle.rows()), 'actual trees, order/decode or admission differs from oracle'
    assert len(rows) == 13332 and sum(row[6] for row in rows) == 11603
    for key in [r['key'] for r in oracle.rules()]:
        assert any(r[5] == key and r[6] for r in rows), key
    assert ieee == ['ORDER_IEEE nan_eq=false nan_le=false nan_ge=false zeros_equal=true zeros_bits_equal=false']
    return dict(rows=len(rows), admitted=11603, excluded=1729, scalar_samples=303,
                actual_trees=len(trees), profiles=len(profiles), ieee_observation_rows=len(ieee))


def validate_result(result, root=ROOT):
    frozen = check_inputs(root)
    assert result['status'] == 'kernel_complete_declared_mathematical_value_family'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(root/MANIFEST)
    assert result['profile_units'] == frozen['profile_units'] and result['profile_unit_count'] == 176
    assert result['rule_order_instance_count'] == 44
    assert set(result['certificate_axioms']) == set(frozen['certificates'])
    for values in result['certificate_axioms'].values(): assert set(values) <= ALLOWED
    assert result['counterexample_certificates'] == frozen['counterexample_certificates']
    assert result['covered_candidate_benchmark_labels'] == frozen['candidate_benchmark_labels']
    assert result['controls'] == validate_controls(result['control_stdout'])
    rejection = result['binary32_order_rejection']
    assert rejection['returncode'] != 0 and re.search(r'error(?:\(|:)', rejection['diagnostic'])
    assert all(token in rejection['diagnostic'] for token in ('LinearOrder', 'failed to synthesize'))
    for key in FALSE_FIELDS: assert result[key] is False, key
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0 and result['mathematical_obligation_denominator'] is None


def main():
    frozen = check_inputs()
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT, text=True, capture_output=True)
    assert build.returncode == 0, build.stdout+build.stderr
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/OrderFamilyControls.lean'], cwd=ROOT,
                         text=True, capture_output=True)
    assert run.returncode == 0, run.stdout+run.stderr
    controls = validate_controls(run.stdout+run.stderr)
    invalid = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/InvalidOrderBinary32.lean'],
                             cwd=ROOT, text=True, capture_output=True)
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']: assert digest(ROOT/row['path']) == row['sha256'], row['path']
    axioms = {n: a for n, a in theory['axiom_dependencies'].items() if '.OrderFamily.' in n}
    result = dict(status='kernel_complete_declared_mathematical_value_family', manifest=MANIFEST,
        manifest_sha256=digest(ROOT/MANIFEST), profile_units=profile_units(), profile_unit_count=176,
        rule_order_instance_count=44, certificate_axioms=axioms,
        counterexample_certificates=frozen['counterexample_certificates'],
        covered_candidate_benchmark_labels=frozen['candidate_benchmark_labels'],
        observations='pure exact ordered values or Boolean predicates; words preserve actual bits; no IEEE totality',
        controls=controls, control_stdout=run.stdout+run.stderr,
        binary32_order_rejection=dict(returncode=invalid.returncode, diagnostic=invalid.stdout+invalid.stderr),
        whole_benchmark_records_closed=0, mathematical_obligation_denominator=None,
        code_correspondence_future_work=True, **{key: False for key in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/order-values-family.json').write_text(json.dumps(result, indent=2)+'\n')
    print('Order family: 44 rule/order instances, 176 declared profiles, 18 checked statements; '
          '13332 controls retain 11603 admitted and 1729 excluded rows. Full workload remains open.')


if __name__ == '__main__': main()
