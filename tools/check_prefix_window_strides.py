"""Supplement the first prefix controls with nonzero outputs on strided retained axes."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
from check_prefix_window import check_inputs as base_inputs

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = 'census/prefix-window-stride-controls-v1.json'
EXPECTED = [dict(name='before', trace=[5, 6], direct=[5, 6], value=56),
            dict(name='after', trace=[3, 6], direct=[3, 6], value=36),
            dict(name='both_last', trace=[21, 24, 27], direct=[21, 24, 27], value=2367),
            dict(name='both_interior', trace=[0, 21, 24], direct=[21, 24], value=234)]


def digest(path):
    return hashlib.sha256(Path(path).read_bytes()).hexdigest()


def check_inputs():
    base_inputs()
    manifest = json.loads((ROOT / MANIFEST).read_text())
    base = manifest['base_manifest']
    assert digest(ROOT / base['path']) == base['sha256']
    for row in manifest['files']:
        assert digest(ROOT / row['path']) == row['sha256'], row['path']
    return manifest


def validate_result(result):
    check_inputs()
    assert result['manifest'] == MANIFEST and result['manifest_sha256'] == digest(ROOT / MANIFEST)
    assert result['controls'] == EXPECTED
    assert result['core_lean_sources_changed'] is False
    assert result['universal_proof_replaced_by_controls'] is False
    assert result['code_correspondence_performed'] is False


def main():
    check_inputs()
    run = subprocess.run(['lake', 'env', 'lean', 'tests/fixtures/PrefixWindowStrideControls.lean'],
                         cwd=ROOT, text=True, capture_output=True)
    assert run.returncode == 0 and 'warning:' not in run.stdout + run.stderr, run.stdout + run.stderr
    pattern = (r'^PREFIX_STRIDE name=(\w+) trace=(\[[\d, ]*\]) '
               r'direct=(\[[\d, ]*\]) value=(\d+)$')
    rows = [dict(name=n, trace=json.loads(t), direct=json.loads(d), value=int(v))
            for n, t, d, v in re.findall(pattern, run.stdout, re.M)]
    result = dict(manifest=MANIFEST, manifest_sha256=digest(ROOT / MANIFEST), controls=rows,
                  control_stdout=run.stdout, core_lean_sources_changed=False,
                  universal_proof_replaced_by_controls=False, code_correspondence_performed=False)
    validate_result(result)
    (ROOT / 'reports/prefix-window-stride-controls.json').write_text(json.dumps(result, indent=2)+'\n')
    print('Four nonzero retained-stride output controls agree; core proofs and v1 packet unchanged.')


if __name__ == '__main__':
    main()
