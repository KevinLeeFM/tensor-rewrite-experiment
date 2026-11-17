#!/usr/bin/env python3
"""Fresh frozen-goal, contamination, negative-control and axiom replay."""
import datetime, hashlib, json, os, pathlib, re, subprocess, tempfile, time
root = pathlib.Path(__file__).resolve().parents[2]
base = 'comparisons/heldout-dynamic-transpose/'
manifest = json.loads((root / base / 'freeze.json').read_text())
for name, digest in manifest['files'].items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
proof = root / base / 'candidate/Proof.lean'
assert not re.search(r'\b(sorry|admit|native_decide|axiom)\b',
                     '\n'.join(line for line in proof.read_text().splitlines()
                               if not line.lstrip().startswith('#print axioms')))
lean = os.environ.get('LEAN', 'lean')
version = subprocess.run([lean, '--version'], capture_output=True, text=True, check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
files = [(f'TensorRewrite/Pilot/{name}.lean', f'TensorRewrite/Pilot/{name}.olean')
         for name in ['Tensor', 'Indexing', 'Permutation', 'ConstantGuard', 'DynamicIndexValue', 'DynamicIndexBounds', 'DynamicIndex']]
files += [(base + src + '.lean', dst + '.olean') for src, dst in
          [('Spec','Spec'),('SpecTests','SpecTests'),('Guard','Guard'),('candidate/Proof','Proof'),('Audit','Audit')]]
records = []; start = time.monotonic()
with tempfile.TemporaryDirectory(prefix='broadcast-acceptance-') as temp:
    b = pathlib.Path(temp); env = os.environ.copy(); env['LEAN_PATH'] = temp
    def run(source, destination=None, marker=None, negative=False):
        target = (b / ('negative' if negative else '') / destination) if destination else None
        if target: target.parent.mkdir(parents=True, exist_ok=True)
        e = env.copy()
        if negative: e['LEAN_PATH'] = str(b / 'negative') + os.pathsep + temp
        argv = [lean, source] + (['-o', str(target)] if target else [])
        t = time.monotonic(); result = subprocess.run(argv, cwd=root, env=e, text=True,
                            capture_output=True, timeout=30)
        output = result.stdout + result.stderr
        records.append({'source': source, 'seconds': time.monotonic() - t,
                        'exit_code': result.returncode, 'expected_failure': marker, 'output': output})
        if marker: assert result.returncode != 0 and marker in output, output
        else: assert result.returncode == 0 and 'warning:' not in output and 'sorryAx' not in output, output
    for src, dest in files: run(src, dest)
    audit = records[-1]['output']
    assert 'DYNAMIC_TRANSPOSE_BASELINE_GUARD checked=' in audit and 'DYNAMIC_TRANSPOSE_SIGNATURE exact' in audit
    matches = re.findall(r'depends on axioms: \[([^\]]+)\]', audit, re.S)
    assert matches and set(x.strip() for x in matches[-1].split(',')) <= {'propext', 'Classical.choice', 'Quot.sound'}, audit
    run('comparisons/heldout-unit-reverse-v1/controls/Forbidden.lean', 'Forbidden.olean', negative=True)
    run(base + 'controls/Leak.lean', marker='DYNAMIC_TRANSPOSE_BASELINE_LEAK', negative=True)
    run(base + 'controls/WrongSignature.lean', marker='DYNAMIC_TRANSPOSE_SIGNATURE_MISMATCH')
    run(base + 'controls/FalseReplacement.lean', marker='Tactic `decide` proved that the proposition', negative=False)
receipt = {'utc': datetime.datetime.now(datetime.timezone.utc).isoformat(), 'version': version,
           'seconds': time.monotonic() - start, 'result': 'passed', 'records': records,
           'proof_sha256': hashlib.sha256(proof.read_bytes()).hexdigest(),
           'freeze_sha256': hashlib.sha256((root/base/'freeze.json').read_bytes()).hexdigest(),
           'forbidden_inventory_sha256': hashlib.sha256((root/'comparisons/fixed-tactics-v1/forbidden.json').read_bytes()).hexdigest()}
print(json.dumps(receipt, indent=2))
