#!/usr/bin/env python3
"""Replay the frozen statement and preproof controls offline."""
import datetime, hashlib, json, os, pathlib, subprocess, tempfile, time
root = pathlib.Path(__file__).resolve().parents[2]
base = 'comparisons/heldout-dynamic-transpose/'
manifest = json.loads((root / base / 'freeze.json').read_text())
for name, digest in manifest['files'].items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
lean = os.environ.get('LEAN', 'lean')
version = subprocess.run([lean, '--version'], capture_output=True, text=True, check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
files = [(f'TensorRewrite/Pilot/{name}.lean', f'TensorRewrite/Pilot/{name}.olean')
         for name in ['Tensor','Indexing','Permutation','ConstantGuard','DynamicIndexValue','DynamicIndexBounds','DynamicIndex']]
files += [(base + name + '.lean', name + '.olean') for name in ['Spec', 'SpecTests']]
records = []; start = time.monotonic()
with tempfile.TemporaryDirectory(prefix='dynamic-unit-spec-') as temp:
    env = os.environ.copy(); env['LEAN_PATH'] = temp
    for source, destination in files:
        target = pathlib.Path(temp) / destination; target.parent.mkdir(parents=True, exist_ok=True)
        t = time.monotonic()
        result = subprocess.run([lean, source, '-o', str(target)], cwd=root, env=env,
                                capture_output=True, text=True, timeout=30)
        output = result.stdout + result.stderr
        records.append({'source': source, 'seconds': time.monotonic() - t,
                        'exit_code': result.returncode, 'output': output})
        assert result.returncode == 0 and 'warning:' not in output and 'sorryAx' not in output, output
    output = records[-2]['output']
    assert 'Heldout.DynamicTranspose.Goal' in output
    assert 'depends on axioms: [propext, Classical.choice, Quot.sound]' in output, output
print(json.dumps({'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'version': version,
                  'seconds': time.monotonic() - start, 'records': records, 'result': 'passed'}, indent=2))
