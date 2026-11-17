#!/usr/bin/env python3
"""Audit committed records without executing Lean or proving source provenance."""
import ast,collections,hashlib,json,pathlib,re,subprocess
root=pathlib.Path(__file__).resolve().parents[3];p=root/'comparisons/indexmaps-core-integration-20261117';full=p/'snork-full-theory-run';down=p/'snork-full-downstream-replay'
def digest(f):return hashlib.sha256(f.read_bytes()).hexdigest()
for row in json.loads((full/'MANIFEST.json').read_text()):
 f=full/row['name'];assert f.stat().st_size==row['bytes'] and digest(f)==row['sha256'],row['name']
for n,h in json.loads((down/'SHA256SUMS.json').read_text()).items(): assert digest(down/n)==h,n
r=json.loads((full/'full-theory-receipt.json').read_text());assert r['returncode']==0 and r['source_commit']=='938b193d4fadbd5e3209b775a88823b9d114715e'
assert not (full/'full-theory.stderr.txt').read_bytes()
a=json.loads((full/'theory-progress.json').read_text()); assert a['build_exit_code']==a['audit_exit_code']==0
astree=ast.parse((root/'tools/check_theory.py').read_text());tab=next(ast.literal_eval(n.value) for n in astree.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='THEOREMS' for t in n.targets)); expected={'TensorRewrite.Theory.'+g+'.'+n for g,ns in tab.items() for n in ns}; assert len(expected)==727 and set(a['axiom_dependencies'])==expected
allowed={'propext','Classical.choice','Quot.sound'};out=a['audit_stdout'];assert 'sorryAx' not in out and not re.search(r'(?i)\b(?:warning|error)\b',out)
for name in expected:
 m=re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]",out)
 if m: got={s.strip() for s in m[1].split(',') if s.strip()}
 else: assert name+"' does not depend on any axioms" in out,name;got=set()
 assert got==set(a['axiom_dependencies'][name]) and got<=allowed,name
for row in a['files']:assert digest(root/row['path'])==row['sha256'],row['path']
log=(full/'theory-build.log').read_text();assert not re.search(r'(?i)\b(?:warning|error)\b',log) and 'Build completed successfully' in log
c=json.loads((down/'cache-verification.json').read_text());manifest=json.loads((root/'lake-manifest.json').read_text());pins={v['name']:v['rev'] for v in manifest['packages']};assert len(c['packages'])==len(pins)==10 and {v['name'] for v in c['packages']}==set(pins)
assert all(v['expected_rev']==v['actual_rev']==pins[v['name']] and not v['tracked_status'] for v in c['packages'])
z=json.loads((down/'receipt.json').read_text());assert z['result']=='passed_all_19_targets_baseline_and_integration' and len(z['targets'])==len(set(z['targets']))==19 and len(z['records'])==150
assert len(c['direct_artifacts'])==17 and all(v['expected_sha256']==v['actual_sha256']==z['external_direct_artifacts'][v['path']] for v in c['direct_artifacts'])
for row in z['records']:
 rev=z[row['mode']]; content=subprocess.check_output(['git','show',rev+':'+row['file']],cwd=root); assert hashlib.sha256(content).hexdigest()==row['source_sha256'] and row['returncode']==0 and 'sorryAx' not in row['output'] and not re.search(r'(?i)\bwarning\b',row['output']),row['file']
by={m:{x['file']:x for x in z['records'] if x['mode']==m} for m in ['baseline','integration']}
assert all(by['baseline'][t]['output']==by['integration'][t]['output'] for t in z['targets'])
closure=set(c['default_root_local_closure']); contemporaneous={x['path'] for x in a['files']};previous={x['file'] for x in z['records'] if x['mode']=='integration'}
print(json.dumps({'result':'record_integrity_passed_not_full_source_attestation','full_manifest_entries':len(json.loads((full/'MANIFEST.json').read_text())),'cache_manifest_entries':len(json.loads((down/'SHA256SUMS.json').read_text())),'theory_axiom_names':len(expected),'theory_file_hash_rows':len(a['files']),'theory_file_unique_paths':len(contemporaneous),'closure_paths':len(closure),'closure_paths_missing_full_run_hash':len(closure-contemporaneous),'closure_paths_missing_full_or_prior19_hash':len(closure-(contemporaneous|previous)),'package_pin_rows':len(c['packages']),'direct_cache_artifacts':len(c['direct_artifacts']),'targets':len(z['targets']),'records':len(z['records']),'full_run_seconds':r['elapsed_seconds'],'full_run_exit':r['returncode']},indent=2))
