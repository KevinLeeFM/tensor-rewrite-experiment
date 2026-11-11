"""Replay frozen exact numerical graphs and independent controls, with no source correspondence."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from fractions import Fraction
import numerical_examples as oracle

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/numerical-values-v1.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
FALSE_FIELDS = ('rounded_transcendentals_modeled', 'floating_point_division_modeled',
                'fast_math_permissions_modeled', 'word_division_is_field_division',
                'full_family_complete', 'full_workload_complete', 'independently_reviewed_statements',
                'benchmark_correspondence_certified', 'code_correspondence_performed')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    manifest = json.loads((root/MANIFEST).read_text())
    assert manifest['model'] == 'exact_numerical_value_graphs_v1'
    assert len(manifest['certificates']) == len(set(manifest['certificates'])) == 53
    assert len(manifest['counterexample_certificates']) == 5
    assert set(manifest['counterexample_certificates']) <= set(manifest['certificates'])
    assert len(manifest['candidate_benchmark_labels']) == 33
    for row in manifest['files']:
        assert digest(root/row['path']) == row['sha256'], row['path']
    assert digest(root/'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['real_power_semantics'] == 'Mathlib Real.rpow; negative base uses real part of principal complex power'
    assert manifest['complex_power_semantics'] == 'Mathlib Complex.cpow; principal log, 0^0=1, 0^w=0 for w!=0'
    assert manifest['reciprocal_square_root'] == 'explicit inverse of actual Real.sqrt or Complex.sqrt'
    assert manifest['field_zero_inverse'] == 0
    assert manifest['complex_log_power_nonzero_base_required'] is True
    assert manifest['complex_log_power_strip'] == dict(lower='-pi', lower_strict=True,
                                                      upper='pi', upper_strict=False)
    assert manifest['real_rsqrt_inverse_square_original_target_iff'] == 'every tensor value is nonnegative'
    assert manifest['control_scope'] == 'development controls; symbolic exact analysis and executable rationals; no held-out independent review'
    assert manifest['source_guards_adopted_as_proof_assumptions'] is False
    assert manifest['mathematical_obligation_denominator'] is None
    return manifest


def extract_axioms(stdout, names):
    output = {}
    for name in names:
        match = re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]", stdout)
        if match:
            axioms = sorted(item.strip() for item in match[1].split(',') if item.strip())
        else:
            assert name+"' does not depend on any axioms" in stdout, name
            axioms = []
        assert set(axioms) <= ALLOWED, (name, axioms)
        output[name] = axioms
    return output


def validate_controls(stdout):
    assert not re.search(r'(?:error(?:\(|:)|warning:)', stdout), stdout[-3000:]
    actual_field, actual_counts, actual_graph = [], [], []
    for line in stdout.splitlines():
        if line.startswith('NUM_FIELD '):
            match = re.fullmatch(r'NUM_FIELD sample=(\d+) input=([\d,\-]+) lhs=(\S+) rhs=(\S+)', line)
            assert match, line
            actual_field.append((int(match[1]), tuple(map(int, match[2].split(','))),
                                 tuple(map(Fraction, match[3].split(','))),
                                 tuple(map(Fraction, match[4].split(',')))))
        elif line.startswith('NUM_GRAPH_COUNT '):
            match = re.fullmatch(r'NUM_GRAPH_COUNT scenario=(\d+) small=(\[.*?\]) output=(\[.*?\]) axes=(\[.*?\])', line)
            assert match, line
            actual_counts.append((int(match[1]), *map(json.loads, match.groups()[1:])))
        elif line.startswith('NUM_GRAPH '):
            match = re.fullmatch(r'NUM_GRAPH scenario=(\d+) output=(\d+) rule=(\w+) lhs=(\S+) rhs=(\S+)', line)
            assert match, line
            actual_graph.append((int(match[1]), int(match[2]), match[3], Fraction(match[4]), Fraction(match[5])))
    expected_counts, expected_graph = oracle.graph_rows()
    assert actual_field == oracle.field_rows(), 'rational field expressions differ'
    assert actual_counts == expected_counts, 'Broadcast shape/axis controls differ'
    assert actual_graph == expected_graph, 'actual Broadcast graph values differ'
    assert len(actual_field) == 625 and len(actual_graph) == 48
    names = ['NumericalControls.'+name for name in oracle.SYMBOLIC]
    return extract_axioms(stdout, names)


def validate_result(result, root=ROOT):
    manifest = check_inputs(root)
    assert result['status'] == 'kernel_checked_exact_numerical_value_graphs_with_domain_refutations'
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(root/MANIFEST)
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert result['checked_statement_count'] == 53
    assert result['counterexample_certificates'] == manifest['counterexample_certificates']
    assert result['certificate_profiles'] == manifest['certificate_profiles']
    assert result['candidate_benchmark_labels'] == manifest['candidate_benchmark_labels']
    assert result['rational_scalar_expression_pairs'] == 5625
    assert result['rational_input_quadruples'] == 625
    assert result['broadcast_value_pairs'] == 48 and result['broadcast_shape_profiles'] == 5
    assert result['symbolic_control_axioms'] == validate_controls(result['control_stdout'])
    for values in result['certificate_axioms'].values():
        assert set(values) <= ALLOWED
    rejection = result['word_field_rejection']
    assert rejection['returncode'] != 0
    assert re.search(r'error(?:\(|:)', rejection['diagnostic'])
    assert all(token in rejection['diagnostic'] for token in ('Field', 'BitVec', 'failed to synthesize'))
    for key in FALSE_FIELDS:
        assert result[key] is False, key
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None


def main():
    manifest = check_inputs()
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT, text=True, capture_output=True)
    assert build.returncode == 0, build.stdout+build.stderr
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/NumericalControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout+run.stderr
    controls = validate_controls(run.stdout+run.stderr)
    invalid = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/InvalidNumericalWordField.lean'],
                             cwd=ROOT, text=True, capture_output=True)
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for row in theory['files']:
        assert digest(ROOT/row['path']) == row['sha256'], row['path']
    axioms = {name: values for name, values in theory['axiom_dependencies'].items()
              if '.Numerical.' in name}
    result = dict(status='kernel_checked_exact_numerical_value_graphs_with_domain_refutations',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT/MANIFEST),
                  certificate_axioms=axioms, checked_statement_count=len(axioms),
                  certificate_profiles=manifest['certificate_profiles'],
                  candidate_benchmark_labels=manifest['candidate_benchmark_labels'],
                  counterexample_certificates=manifest['counterexample_certificates'],
                  rational_scalar_expression_pairs=5625, rational_input_quadruples=625,
                  broadcast_value_pairs=48, broadcast_shape_profiles=5,
                  symbolic_control_axioms=controls, control_stdout=run.stdout+run.stderr,
                  word_field_rejection=dict(returncode=invalid.returncode,
                                            diagnostic=invalid.stdout+invalid.stderr),
                  whole_benchmark_records_closed=0, mathematical_obligation_denominator=None,
                  code_correspondence_future_work=True, **{name: False for name in FALSE_FIELDS})
    validate_result(result)
    (ROOT/'reports/numerical-values.json').write_text(json.dumps(result, indent=2)+'\n')
    print('Numerical graphs: 53 statements, 5 refutations, 5625 rational and 48 Broadcast pairs; '
          'exact value profiles only; full workload remains open.')


if __name__ == '__main__':
    main()
