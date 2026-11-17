#!/usr/bin/env python3
"""Replay one frozen, isolated Std-only mathematical target and its controls offline."""
from pathlib import Path
import datetime, hashlib, json, os, re, subprocess, time

p = Path(__file__).resolve().parent
root = p.parents[1]
m = json.loads((p / 'frozen-manifest.json').read_text())
for relative, digest in m['inputs'].items():
    assert hashlib.sha256((p / relative).read_bytes()).hexdigest() == digest, relative
for relative, digest in m['sources'].items():
    assert hashlib.sha256((root / relative).read_bytes()).hexdigest() == digest, relative
proof = (p / 'Proof.lean').read_text()
imports = re.findall(r'^\s*(?:public\s+)?import\s+(\S+)', proof, re.M)
assert imports and set(imports) <= set(m['allowed_proof_imports']), imports
assert not re.search(r'\b(sorry|admit|native_decide|axiom|unsafe|implemented_by|extern)\b', proof)
assert not re.search(r'^\s*(?:public\s+)?(?:meta\s+)?def\s+Goal\b', proof, re.M)
b = p / 'replay-build'
assert not b.exists(), 'Use a fresh copy or explicitly remove only generated replay-build before rerunning'
b.mkdir()
c = b / 'controls'
c.mkdir()
lean = os.environ.get('LEAN', 'lean')
env = os.environ.copy()
env['LEAN_PATH'] = str(b)
records = []
t0 = time.monotonic()
started = datetime.datetime.now(datetime.timezone.utc).isoformat()

def run(file, output=None, expected=None, control_path=False):
    args = [lean, str(p / file)]
    if output:
        out = (c if control_path else b) / output
        out.parent.mkdir(parents=True, exist_ok=True)
        args += ['-o', str(out)]
    process_env = env.copy()
    if control_path:
        process_env['LEAN_PATH'] = str(c) + os.pathsep + str(b)
    t = time.monotonic()
    r = subprocess.run(args, cwd=root, env=process_env, capture_output=True, text=True, timeout=30)
    text = r.stdout + r.stderr
    row = dict(file=file, seconds=time.monotonic()-t, returncode=r.returncode,
               output=text, expected_failure=expected)
    records.append(row)
    (p / 'cloud-replay.json').write_text(json.dumps(dict(started_utc=started,
        elapsed_seconds=time.monotonic()-t0, records=records), indent=2)+'\n')
    print(json.dumps(row), flush=True)
    if expected:
        assert r.returncode != 0 and expected in text, row
        assert not any(s in text for s in ['unknown identifier', 'unexpected token', 'failed to synthesize']), row
    else:
        assert r.returncode == 0 and 'sorry' not in text, row
    return text

version = subprocess.run([lean, '--version'], capture_output=True, text=True, check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version, version
for source, output in [
    ('baseline/TensorRewrite/Pilot/Tensor.lean', 'TensorRewrite/Pilot/Tensor.olean'),
    ('baseline/TensorRewrite/Pilot/Indexing.lean', 'TensorRewrite/Pilot/Indexing.olean'),
    ('Spec.lean', 'Spec.olean'), ('Guard.lean', 'Guard.olean'),
    ('BasisAudit.lean', 'BasisAudit.olean'), ('Proof.lean', 'Proof.olean'),
    ('Witnesses.lean', 'Witnesses.olean'), ('Audit.lean', 'Audit.olean')]:
    run(source, output)
output = records[-1]['output']
axioms = re.findall(r'depends on axioms: \[([^\]]*)\]', output)
assert axioms, output
for group in axioms:
    assert set(x.strip() for x in group.split(',') if x.strip()) <= set(m['allowed_axioms']), group
run('controls/Forbidden.lean', 'Forbidden.olean', control_path=True)
run('FalseTrial.lean', expected='not definitionally equal')
run('LeakTrial.lean', expected='HELDOUT_BASELINE_LEAK', control_path=True)
run('SignatureTrial.lean', expected='HELDOUT_SIGNATURE_MISMATCH')
result = dict(started_utc=started, ended_utc=datetime.datetime.now(datetime.timezone.utc).isoformat(),
    elapsed_seconds=time.monotonic()-t0, compiler=version, frozen_inputs_unchanged=True,
    proof_sha256=hashlib.sha256((p/'Proof.lean').read_bytes()).hexdigest(),
    all_checks_passed=True, records=records)
(p/'cloud-replay.json').write_text(json.dumps(result, indent=2)+'\n')
print(json.dumps({k:v for k,v in result.items() if k != 'records'}, indent=2))
