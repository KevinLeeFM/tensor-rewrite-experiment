import os,re,json,hashlib,pathlib,subprocess,time,sys
root=pathlib.Path.cwd(); base=root/'comparisons/heldout-space-depth-selection'; lean='/workspace/toolchains/lean-4.35.0-linux/bin/lean'; tmp=pathlib.Path('/tmp/space-depth-independent-aa5521');tmp.mkdir(exist_ok=True); out=tmp/'olean';out.mkdir(exist_ok=True)
print(subprocess.check_output([lean,'--version'],text=True).strip(),flush=True)
for f in sorted(base.glob('*freeze.json')):
 d=json.loads(f.read_text()); files=d.get('files',{}); bad=[p for p,h in files.items() if not (root/p).exists() or hashlib.sha256((root/p).read_bytes()).hexdigest()!=h]; print('FREEZE',f.name,len(files),'BAD',bad,flush=True)
 if bad:sys.exit(2)
roots=['OtherAxisIntegration','GoalCandidateTests','SplitStrategyControls','ActualTransportInstanceControl']
seen=set();ordered=[]
def visit(mod):
 if mod in seen:return
 seen.add(mod)
 paths=[root/(mod.replace('.','/')+'.lean'),base/(mod+'.lean')]; paths=[x for x in paths if x.exists()]
 if not paths:return
 p=paths[0]; s=p.read_text()
 for line in s.splitlines():
  m=re.match(r'^\s*(?:public\s+)?import\s+([\w.]+)',line)
  if m:visit(m.group(1))
 ordered.append((mod,p))
for r in roots:visit(r)
print('CLOSURE',len(ordered),flush=True)
for mod,p in ordered:
 s=p.read_text(); hits=[(i,l.strip()) for i,l in enumerate(s.splitlines(),1) if re.search(r'\b(sorry|admit|native_decide|axiom)\b',l) and not l.strip().startswith(('--','/--','/-','*'))];
 if hits: print('SCAN',p.relative_to(root),hits,flush=True)
env=os.environ.copy();env['LEAN_PATH']=str(out);start=time.monotonic();rows=[]
for mod,p in ordered:
 target=out/(mod.replace('.','/')+'.olean');target.parent.mkdir(parents=True,exist_ok=True);t=time.monotonic();r=subprocess.run([lean,str(p),'-o',str(target)],cwd=root,env=env,text=True,capture_output=True);d=time.monotonic()-t;rows.append((mod,d,r.returncode));print('COMPILE',mod,round(d,3),r.returncode,flush=True); print(r.stdout+r.stderr,flush=True)
 if r.returncode or 'sorryAx' in r.stdout+r.stderr or 'warning:' in r.stdout+r.stderr:sys.exit(3)
print('REPLAY_SECONDS',round(time.monotonic()-start,3),flush=True)
