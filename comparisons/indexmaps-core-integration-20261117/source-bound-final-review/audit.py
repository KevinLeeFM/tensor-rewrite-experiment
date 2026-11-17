#!/usr/bin/env python3
"""Read-only audit of committed source-bound receipts. Does not execute Lean."""
import ast,collections,hashlib,importlib.util,json,pathlib,re,subprocess,time
root=pathlib.Path(__file__).resolve().parents[3];p=root/'comparisons/indexmaps-core-integration-20261117'; rev='938b193d4fadbd5e3209b775a88823b9d114715e'; t=time.monotonic()
def sha(f):return hashlib.sha256(f.read_bytes()).hexdigest()
def load(f):return json.loads(f.read_text())
manifest_counts={};pres=[];posts=[];receipts=[]
for suffix in ['', '2','3']:
 d=p/('snork-source-bound-replay'+suffix);m=load(d/'MANIFEST.json')
 for z in m:
  f=d/z['name'];assert f.stat().st_size==z['bytes'] and sha(f)==z['sha256'],str(f)
 manifest_counts[suffix or '1']=len(m);pres.append(load(d/'source-pre.json'));posts.append(load(d/'source-post.json'));receipts.append(load(d/'receipt.json'))
assert [r['returncode'] for r in receipts]==[125,1,0]
assert all(pre['source_commit']==rev and pre['archive_sha256']=='906ba13644f304b8b4de0094ec0a6e3ecb7727b7022acec70dfe32e045413663' and pre['hashes']==post['hashes'] and post['equal_pre'] for pre,post in zip(pres,posts))
proc=subprocess.Popen(['git','archive',rev],cwd=root,stdout=subprocess.PIPE);h=hashlib.sha256()
for chunk in iter(lambda:proc.stdout.read(1048576),b''):h.update(chunk)
assert proc.wait()==0 and h.hexdigest()==pres[2]['archive_sha256']
raw=subprocess.check_output(['git','ls-tree','-r','-z',rev],cwd=root); entries=[]
for x in raw.split(b'\0'):
 if not x:continue
 head,path=x.split(b'\t',1);mode,typ,oid=head.decode().split();assert typ=='blob' and mode in ('100644','100755');entries.append((path.decode(),oid))
assert len(entries)==2610 and all(set(x['hashes'])=={n for n,_ in entries} for x in pres+posts)
proc=subprocess.Popen(['git','cat-file','--batch'],cwd=root,stdin=subprocess.PIPE,stdout=subprocess.PIPE)
for name,oid in entries:
 proc.stdin.write((oid+'\n').encode());proc.stdin.flush();hdr=proc.stdout.readline().decode().split();assert len(hdr)==3 and hdr[1]=='blob';remaining=int(hdr[2]);h=hashlib.sha256()
 while remaining:
  b=proc.stdout.read(min(remaining,1048576));assert b;h.update(b);remaining-=len(b)
 assert proc.stdout.read(1)==b'\n';assert all(x['hashes'][name]==h.hexdigest() for x in pres+posts),name
proc.stdin.close();assert proc.wait()==0
spec=importlib.util.spec_from_file_location('measure',root/'comparisons/tensorright-v1/measure_dependencies.py');mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod);closure=set()
for name in ['TensorRewrite.lean','TensorRewriteLibraries.lean','TensorRewriteTheory.lean','tests/fixtures/TheoryAudit.lean']:closure|=mod.closure(root/name)
closure={str(x.relative_to(root)) for x in closure};assert len(closure)==242 and all(set(x['closure'])==closure for x in pres)
for name in ['tools/check_theory.py','tools/lean_size.py','tests/fixtures/TheoryAudit.lean','census/lean-category-overrides-v1.json','lakefile.toml','lake-manifest.json','lean-toolchain','reports/library-setup.json','reports/pilot-values.json']:
 assert name in pres[2]['hashes'],name
r3=receipts[2];cmd=r3['command'];assert '--network' in cmd and cmd[cmd.index('--network')+1]=='none';mounts=[cmd[i+1] for i,x in enumerate(cmd) if x=='--mount'];assert len(mounts)==6
for token in ['/source,dst=/work,readonly','/.lake/packages,readonly','/toolchain,readonly','/reports/theory-build.log,dst=/work/reports/theory-build.log','/reports/theory-progress.json,dst=/work/reports/theory-progress.json']:
 assert any(token in x for x in mounts),token
assert any('source-bound-replay2-20261117/lake,dst=/work/.lake' in x for x in mounts)
assert 'FileNotFoundError' in (p/'snork-source-bound-replay2/stderr.txt').read_text() and 'reports/library-setup.json' in (p/'snork-source-bound-replay2/stderr.txt').read_text()
assert 'failed to create task' in (p/'snork-source-bound-replay/stderr.txt').read_text()
for suffix in ['2','3']:
 log=(p/('snork-source-bound-replay'+suffix)/'theory-build.log').read_text();assert 'Build completed successfully (3721 jobs).' in log and not re.search(r'(?i)\b(?:warning|error)\b',log)
full=p/'snork-source-bound-replay3';assert not (full/'stderr.txt').read_bytes();progress=load(full/'theory-progress.json');assert progress['build_exit_code']==progress['audit_exit_code']==0 and not progress['code_correspondence_performed']
tree=ast.parse((root/'tools/check_theory.py').read_text());tab=next(ast.literal_eval(n.value) for n in tree.body if isinstance(n,ast.Assign) and any(isinstance(z,ast.Name) and z.id=='THEOREMS' for z in n.targets));names={'TensorRewrite.Theory.'+g+'.'+v for g,vs in tab.items() for v in vs};assert len(names)==727 and set(progress['axiom_dependencies'])==names
out=progress['audit_stdout'];allowed={'propext','Classical.choice','Quot.sound'};assert not re.search(r'(?i)\b(?:warning|error)\b|sorryAx',out)
for name in names:
 m=re.search(re.escape(name)+r"' depends on axioms: \[([^\]]*)\]",out)
 if m:actual={x.strip() for x in m[1].split(',') if x.strip()}
 else:assert name+"' does not depend on any axioms" in out,name;actual=set()
 assert actual==set(progress['axiom_dependencies'][name]) and actual<=allowed,name
for z in progress['files']:assert sha(root/z['path'])==z['sha256'],z['path']
prior=p/'snork-full-downstream-replay';sums=load(prior/'SHA256SUMS.json');assert all(sha(prior/n)==h for n,h in sums.items())
cache=load(prior/'cache-verification.json');manifest=load(root/'lake-manifest.json');pins={x['name']:x['rev'] for x in manifest['packages']};assert len(pins)==len(cache['packages'])==10 and all(x['expected_rev']==x['actual_rev']==pins[x['name']] and not x['tracked_status'] for x in cache['packages'])
cases=load(root/'comparisons/tensorright-v1/cases.json')['cases'];assert len(cases)==118
for c in cases:assert sha(root/c['lean_proof_file'])==c['lean_proof_sha256'],c['id']
z=load(p/'snork-full-downstream-replay/receipt.json');inventory=load(p/'downstream-inventory.json');assert z['result']=='passed_all_19_targets_baseline_and_integration' and len(z['records'])==150 and len(z['targets'])==19 and set(z['targets'])=={x['paper_target'] for x in inventory['targets']}
for row in z['records']:
 data=subprocess.check_output(['git','show',z[row['mode']]+':'+row['file']],cwd=root)
 assert hashlib.sha256(data).hexdigest()==row['source_sha256'] and row['returncode']==0 and not re.search(r'(?i)\bwarning\b|sorryAx',row['output']),row['file']
assert len(cache['direct_artifacts'])==17 and all(x['expected_sha256']==x['actual_sha256']==z['external_direct_artifacts'][x['path']] for x in cache['direct_artifacts'])
by={mode:{x['file']:x for x in z['records'] if x['mode']==mode} for mode in ['baseline','integration']};assert all(by['baseline'][n]['output']==by['integration'][n]['output'] for n in z['targets'])
target_axiom_reports={}
for mode in ['baseline','integration']:
 count=0
 for target in z['targets']:
  output=by[mode][target]['output']; lines=re.findall(r"^'[^']+' (?:does not depend on any axioms|depends on axioms: \[)",output,re.M);assert lines,target;count+=len(lines)
  for group in re.findall(r'depends on axioms: \[([^\]]*)\]',output):assert {x.strip() for x in group.split(',') if x.strip()}<=allowed,target
 target_axiom_reports[mode]=count
print(json.dumps({'result':'committed_evidence_internally_consistent_not_independent_build','source_revision':rev,'archive_sha256':pres[2]['archive_sha256'],'git_blobs_checked':len(entries),'snapshots_checked':6,'closure_paths':len(closure),'attempts':[{'returncode':r['returncode'],'seconds':r['elapsed_seconds']} for r in receipts],'manifest_counts':manifest_counts,'axiom_names':len(names),'prior_evidence_hashes':len(sums),'package_observations':len(cache['packages']),'direct_artifact_observations':len(cache['direct_artifacts']),'paper_statement_hashes':len(cases),'downstream_targets':len(z['targets']),'downstream_records':len(z['records']),'target_axiom_reports':target_axiom_reports,'cache_handoff':'replay3 mounts replay2 lake path; build log is cached','dependency_trust':'read-only reused external packages, not rebuilt','audit_seconds':time.monotonic()-t},indent=2))
