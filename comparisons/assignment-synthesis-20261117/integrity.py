#!/usr/bin/env python3
"""Read-only reconciliation of preserved case evidence; not a proof checker."""
import collections, hashlib, json, pathlib, subprocess, sys
root = pathlib.Path(__file__).resolve().parents[2]
comparison = root / 'comparisons/tensorright-v1'
data = json.loads((comparison / 'cases.json').read_text())
rows = data['cases']
errors = []
ids = [x['id'] for x in rows]
if len(ids) != 118 or len(set(ids)) != len(ids): errors.append('paper IDs not 118 unique')
outcomes = collections.Counter(x['lean_result'] for x in rows)
expected = {'proved': 116, 'disproved_in_model': 1, 'vacuous_in_paper_model': 1}
if dict(outcomes) != expected: errors.append('paper row outcomes differ from expected')
for row in rows:
    for path_key, hash_key in [('source_path', 'source_sha256'), ('lean_proof_file', 'lean_proof_sha256')]:
        p = root / row[path_key]
        if not p.is_file() or hashlib.sha256(p.read_bytes()).hexdigest() != row[hash_key]:
            errors.append(row['id'] + ': mismatch ' + path_key)
cases = [
 ('unit_axis_reverse', root/'comparisons/heldout-unit-reverse-v1', 'frozen-manifest.json', 'Proof.lean'),
 ('transpose_broadcast', root/'comparisons/heldout-transpose-broadcast', 'freeze.json', 'candidate/Proof.lean'),
 ('dynamic_unit_insertion', root/'comparisons/heldout-dynamic-unit', 'freeze.json', 'candidate/Proof.lean'),
 ('unsigned_remainder_conversion', pathlib.Path('/workspace/tensor-heldout-remainder-cast-20261117/comparisons/heldout-remainder-cast'), 'freeze.json', 'candidate/Proof.lean'),
 ('dynamic_slice_transpose', root/'comparisons/heldout-dynamic-transpose', 'freeze.json', 'candidate/Proof.lean')]
heldout = []
for name, path, freeze, proof in cases:
    files = {}
    for relative in [freeze, proof, 'independent-statement-review.md', 'independent-final-review.md', 'REPORT.md']:
        f = path / relative
        if not f.is_file(): errors.append(name + ': missing ' + relative); continue
        files[relative] = hashlib.sha256(f.read_bytes()).hexdigest()
    heldout.append({'id':name, 'file_hashes':files})
cmd = ['git','diff','--name-only','f468e943febf52567b38b4839c1812eeb5f8ae5d','96dbc9fd86f208859428abecb704abae54f91548','--','TensorRewrite','lean-toolchain','lakefile.toml','lake-manifest.json']
diff = subprocess.run(cmd, cwd=root, text=True, capture_output=True, check=True).stdout.splitlines()
if diff: errors.append('protected baseline files differ')
result = {'method':'read-only existence and hash reconciliation; not independent statement review or Lean replay', 'paper_count':len(ids),'paper_unique_ids':len(set(ids)),'paper_outcomes':dict(outcomes),'paper_source_and_proof_hash_mismatches':0 if not any('mismatch' in x for x in errors) else 'see errors','heldout_artifacts':heldout,'protected_diff':diff,'errors':errors}
print(json.dumps(result,indent=2))
sys.exit(bool(errors))
