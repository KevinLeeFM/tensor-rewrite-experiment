"""Build the library-backed project and audit the new integration theorem dependencies."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
from lean_size import count_source

ROOT = Path(__file__).resolve().parents[1]
THEOREMS = ('integer_factor', 'binary32_add_eq_spec', 'binary32_mul_eq_spec',
            'tensor_binary32_add_eq_spec')
ALLOWED_AXIOMS = {'propext', 'Quot.sound', 'Classical.choice'}


def main():
    manifest = json.loads((ROOT / 'lake-manifest.json').read_text())
    packages = manifest['packages']
    expected = {'mathlib': '56a005855ea17e0b0958f73ec801ae140b0a1679',
                'floatlib': 'acba2057e452f32f4ed4f06bb0adbeda5342ba92'}
    for package in packages:
        revision = subprocess.check_output(
            ['git', 'rev-parse', 'HEAD'], cwd=ROOT / '.lake/packages' / package['name'],
            text=True).strip()
        assert revision == package['rev'], package['name']
    assert {p['name']: p['rev'] for p in packages if p['name'] in expected} == expected
    build = subprocess.run(['lake', 'build'], cwd=ROOT, text=True, capture_output=True)
    (ROOT / 'reports/library-setup-build.log').write_text(build.stdout + build.stderr)
    if build.returncode:
        print((build.stdout + build.stderr)[-6000:]); raise SystemExit(build.returncode)
    audit = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/LibraryAudit.lean'],
                           cwd=ROOT, text=True, capture_output=True)
    assert audit.returncode == 0, audit.stdout + audit.stderr
    dependencies = {}
    for name in THEOREMS:
        full_name = 'TensorRewrite.Libraries.' + name
        match = re.search(re.escape(full_name) + r"' depends on axioms: \[([^\]]*)\]", audit.stdout)
        assert match, audit.stdout
        axioms = {a.strip() for a in match[1].split(',') if a.strip()}
        assert axioms <= ALLOWED_AXIOMS, (full_name, axioms)
        dependencies[full_name] = sorted(axioms)
    paths = [ROOT / 'TensorRewriteLibraries.lean',
             *sorted((ROOT / 'TensorRewrite/Libraries').glob('*.lean'))]
    files = [dict(path=str(p.relative_to(ROOT)), sha256=hashlib.sha256(p.read_bytes()).hexdigest(),
                  **count_source(p.read_text())) for p in paths]
    report = dict(status='passed', lean_toolchain=(ROOT / 'lean-toolchain').read_text().strip(),
                  packages=packages, build_exit_code=build.returncode, audit_exit_code=audit.returncode,
                  axiom_dependencies=dependencies, integration_category='A', integration_files=files,
                  new_integration_code_lines=sum(f['code_lines'] for f in files),
                  previous_std_only_pilot_lines=2763,
                  external_library_lines_counted_as_new=False, source_rewrite_acceptance_claimed=False,
                  scope='selected Mathlib and certified FloatLib binary32 imports; no whole-library semantic audit',
                  audit_stdout=audit.stdout)
    report['total_custom_lean_lines_including_integration'] = 2763 + report['new_integration_code_lines']
    (ROOT / 'reports/library-setup.json').write_text(json.dumps(report, indent=2) + '\n')
    print('Library integration passed: Mathlib, FloatLib, four audited theorems; '
          + str(report['new_integration_code_lines']) + ' new integration Lean lines.')


if __name__ == '__main__':
    main()
