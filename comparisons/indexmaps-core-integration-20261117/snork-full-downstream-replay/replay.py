import pathlib,subprocess,json,re,os,time,hashlib
root=pathlib.Path('/tmp/scout-tensor-indexmaps-20261117');out=pathlib.Path('/tmp/scout-tensor-indexmaps-replay-20261117');base='28b4bf12be2f2252d6422270b0927d5aed631ac6';lean='/home/k323lee/.elan/toolchains/leanprover--lean4---v4.35.0/bin/lean';packages=pathlib.Path('/home/k323lee/type-inf-project/type-inference-toy/tensor-rewrite-experiment/.lake/packages');targets=[t['paper_target'] for t in json.load(open(root/'comparisons/indexmaps-core-integration-20261117/downstream-inventory.json'))['targets']];records=[];start=time.monotonic();external={};result='incomplete'
def save(): (out/'receipt.json').write_text(json.dumps({'result':result,'baseline':base,'integration':'938b193d4fadbd5e3209b775a88823b9d114715e','targets':targets,'seconds':time.monotonic()-start,'records':records,'external_direct_artifacts':external,'limitations':'Imported package artifacts reused; pinned source commits and tracked cleanliness verified, not rebuilt. Serial fresh local module outputs only.'},indent=2))
try:
 for mode in ['baseline','integration']:
  w=out/mode;w.mkdir();texts={};order=[]
  def load(f):
   if f in texts:return
   b=subprocess.check_output(['git','show',base+':'+f],cwd=root) if mode=='baseline' else (root/f).read_bytes();texts[f]=b
   for m in re.findall(r'^(?:public\s+|private\s+)?(?:meta\s+)?import\s+([A-Za-z0-9_.]+)',b.decode(),re.M):
    path=m.replace('.','/')+'.lean'
    if (root/path).exists():load(path)
    elif m!='Std':
     matches=list(packages.glob('*/.lake/build/lib/lean/'+m.replace('.','/')+'.olean'));assert len(matches)==1,(m,matches);fpath=matches[0];external[str(fpath)]=hashlib.sha256(fpath.read_bytes()).hexdigest()
   order.append(f)
  for f in targets:load(f)
  for f,b in texts.items():q=w/f;q.parent.mkdir(parents=True,exist_ok=True);q.write_bytes(b)
  env=dict(os.environ,LEAN_PATH=':'.join([str(w)]+[str(x) for x in packages.glob('*/.lake/build/lib/lean')]))
  for f in order:
   if time.monotonic()-start>300:raise RuntimeError('aggregate 300s review gate reached')
   t=time.monotonic();r=subprocess.run([lean,'-j','1',f,'-o',f[:-5]+'.olean'],cwd=w,env=env,capture_output=True,text=True,timeout=30);log=r.stdout+r.stderr;records.append({'mode':mode,'file':f,'source_sha256':hashlib.sha256(texts[f]).hexdigest(),'seconds':time.monotonic()-t,'returncode':r.returncode,'output':log});save()
   assert r.returncode==0 and 'sorryAx' not in log,(mode,f,log)
 result='passed_all_19_targets_baseline_and_integration'
except Exception as e:
 result='blocked_or_failed';(out/'failure.txt').write_text(repr(e));print(repr(e))
finally:save();print(result,len(records),time.monotonic()-start)
