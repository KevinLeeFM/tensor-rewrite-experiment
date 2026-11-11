"""Audit exact real/principal-complex rewrite domains; no executable float or source claims."""
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/scalar-domains-v2.json'
ALLOWED = {'propext', 'Quot.sound', 'Classical.choice'}
CONTROLS = ('imaginary_square_root', 'imaginary_magnitude', 'full_period_log',
            'upper_branch_endpoint', 'lower_branch_endpoint', 'negative_real_square',
            'empty_nonreal_tensor', 'scalar_nonreal_tensor')


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs(root=ROOT):
    manifest = json.loads((root/MANIFEST).read_text())
    for file in manifest['files']:
        assert digest(root/file['path']) == file['sha256'], file['path']
    assert digest(root/'lake-manifest.json') == manifest['lake_manifest_sha256']
    assert manifest['complex_branch_strip'] == dict(lower='-pi', lower_strict=True,
                                                   upper='pi', upper_strict=False)
    assert manifest['complex_sqrt_square_domain'] == 'imaginary_part_equals_zero'
    assert manifest['real_log_sqrt_domain'] == 'strictly_positive'
    assert len(manifest['profiles']) == 5
    return manifest


def validate_result(result):
    assert result['status'] == 'kernel_checked_exact_real_and_principal_complex_domains'
    assert result['scalar_contract'] == 'exact_real_and_principal_complex'
    for key in ('rounded_transcendentals_modeled', 'fast_math_permissions_modeled',
                'full_scalar_control_family_complete', 'full_workload_complete',
                'independently_reviewed_statements', 'code_correspondence_performed',
                'benchmark_correspondence_certified'):
        assert result[key] is False, key
    assert result['code_correspondence_future_work'] is True
    assert result['whole_benchmark_records_closed'] == 0
    assert result['mathematical_obligation_denominator'] is None
    manifest = check_inputs()
    assert set(result['certificate_axioms']) == set(manifest['certificates'])
    assert result['checked_statement_count'] == len(result['certificate_axioms']) == 14
    assert result['profiles'] == manifest['profiles']
    assert result['counterexample_certificates'] == manifest['counterexample_certificates']
    assert len(result['counterexample_certificates']) == 2
    assert set(result['control_axioms']) == {'ScalarDomainControls.'+n for n in CONTROLS}
    for axioms in list(result['certificate_axioms'].values())+list(result['control_axioms'].values()):
        assert set(axioms) <= ALLOWED


def main():
    manifest = check_inputs()
    build = subprocess.run(['lake', 'build', 'TensorRewriteTheory'], cwd=ROOT,
                           text=True, capture_output=True)
    assert build.returncode == 0, build.stdout+build.stderr
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/ScalarDomainControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0, run.stdout+run.stderr
    assert 'warning:' not in run.stdout+run.stderr, run.stdout+run.stderr
    controls = {}
    for short in CONTROLS:
        name = 'ScalarDomainControls.'+short
        match = re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]", run.stdout)
        if match:
            axioms = sorted(a.strip() for a in match[1].split(',') if a.strip())
        else:
            assert name+"' does not depend on any axioms" in run.stdout, name
            axioms = []
        assert set(axioms) <= ALLOWED
        controls[name] = axioms
    theory = json.loads((ROOT/'reports/theory-progress.json').read_text())
    for file in theory['files']:
        assert digest(ROOT/file['path']) == file['sha256'], file['path']
    certificates = {n: a for n, a in theory['axiom_dependencies'].items()
                    if '.ScalarDomains.' in n}
    result = dict(status='kernel_checked_exact_real_and_principal_complex_domains',
                  manifest=MANIFEST, manifest_sha256=digest(ROOT/MANIFEST),
                  scalar_contract='exact_real_and_principal_complex',
                  profiles=manifest['profiles'], certificate_axioms=certificates,
                  checked_statement_count=len(certificates), control_axioms=controls,
                  control_stdout=run.stdout,
                  counterexample_certificates=manifest['counterexample_certificates'],
                  rounded_transcendentals_modeled=False, fast_math_permissions_modeled=False,
                  full_scalar_control_family_complete=False, full_workload_complete=False,
                  whole_benchmark_records_closed=0, mathematical_obligation_denominator=None,
                  independently_reviewed_statements=False, benchmark_correspondence_certified=False,
                  code_correspondence_performed=False, code_correspondence_future_work=True)
    validate_result(result)
    (ROOT/'reports/scalar-domains.json').write_text(json.dumps(result, indent=2)+'\n')
    print('Scalar domains passed: 14 statements, five explicit profiles, eight symbolic controls; '
          'rounded transcendental semantics and full workload remain open.')


if __name__ == '__main__':
    main()
