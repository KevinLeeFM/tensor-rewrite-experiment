import pathlib,subprocess,json,time,hashlib,tarfile,io,shutil,os
p=pathlib.Path('/tmp/scout-tensor-source-bound-replay-20261117');w=pathlib.Path('/tmp/scout-tensor-indexmaps-20261117');rev='938b193d4fadbd5e3209b775a88823b9d114715e';start=time.time()
assert shutil.disk_usage(p).free>5500000000
archive=subprocess.check_output(['git','archive',rev],cwd=w);root=p/'source';root.mkdir();tarfile.open(fileobj=io.BytesIO(archive)).extractall(root)
closure=json.load(open('/tmp/scout-tensor-indexmaps-replay-20261117/cache-verification.json'))['default_root_local_closure'];assert len(closure)==242
paths=sorted(x.relative_to(root).as_posix() for x in root.rglob('*') if x.is_file());
def hashes():return {n:hashlib.sha256((root/n).read_bytes()).hexdigest() for n in paths}
pre=hashes();assert all(n in pre for n in closure)
(p/'source-pre.json').write_text(json.dumps({'source_commit':rev,'archive_sha256':hashlib.sha256(archive).hexdigest(),'observed_at':time.time(),'closure':closure,'hashes':pre},indent=2))
for d in ['lake','reports']:(p/d).mkdir()
cmd=['docker','run','--name','scout-tensor-source-bound-20261117','--user','1020:1022','--env','HOME=/tmp','--env','PYTHONDONTWRITEBYTECODE=1','--rm','--network','none','--cpus','2','--memory','2g','--mount',f'type=bind,src={root},dst=/work,readonly','--mount',f'type=bind,src={p}/lake,dst=/work/.lake','--mount','type=bind,src=/home/k323lee/type-inf-project/type-inference-toy/tensor-rewrite-experiment/.lake/packages,dst=/work/.lake/packages,readonly','--mount',f'type=bind,src={p}/reports,dst=/work/reports','--mount','type=bind,src=/home/k323lee/.elan/toolchains/leanprover--lean4---v4.35.0,dst=/toolchain,readonly','--workdir','/work','--entrypoint','/bin/sh','ghcr.io/seahorn/seahorn-llvm18:nightly','-c','export PATH=/toolchain/bin:$PATH; lean --version; python3 tools/check_theory.py']
out=open(p/'stdout.txt','w');err=open(p/'stderr.txt','w');proc=subprocess.Popen(cmd,stdout=out,stderr=err);samples=[];reason=None
while proc.poll() is None:
 elapsed=time.time()-start;free=shutil.disk_usage(p).free;samples.append({'elapsed':elapsed,'free_bytes':free});(p/'progress.json').write_text(json.dumps({'pid':proc.pid,'samples':samples,'needs_supervision':elapsed>=600},indent=2))
 if free<5500000000 or elapsed>=86400:
  reason='disk floor' if free<5500000000 else '24-hour stop';subprocess.run(['docker','stop','-t','10','scout-tensor-source-bound-20261117'],capture_output=True);break
 time.sleep(10)
rc=proc.wait();out.close();err.close();post=hashes();(p/'source-post.json').write_text(json.dumps({'observed_at':time.time(),'hashes':post,'equal_pre':post==pre},indent=2));(p/'receipt.json').write_text(json.dumps({'command':cmd,'source_commit':rev,'archive_sha256':hashlib.sha256(archive).hexdigest(),'returncode':rc,'elapsed_seconds':time.time()-start,'source_unchanged':post==pre,'closure_count':len(closure),'stop_reason':reason,'samples':samples,'approval':'Kevin: I approve that. Same 242-module/727-declaration full theory validation scope,2CPU/2GB,offline,10min supervision,5GB safety. Source-bound retry fixes prior attestation omission; previous successful run remains distinct.'},indent=2))
o=w/'comparisons/indexmaps-core-integration-20261117/snork-source-bound-replay';o.mkdir(exist_ok=False)
fs=[p/n for n in ['source-pre.json','source-post.json','receipt.json','stdout.txt','stderr.txt','supervise.py']]+list((p/'reports').glob('*'));manifest=[]
for f in fs:
 if not f.is_file():continue
 assert f.stat().st_size<20000000
 shutil.copyfile(f,o/f.name);manifest.append({'name':f.name,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size})
(o/'MANIFEST.json').write_text(json.dumps(manifest,indent=2));assert subprocess.check_output(['git','branch','--show-current'],cwd=w,text=True).strip()=='scout/indexmaps-snork-replay-20261117';subprocess.run(['git','add','--',str(o.relative_to(w))],cwd=w,check=True);subprocess.run(['git','commit','-m','Preserve source-bound isolated Tensor full-theory replay'],cwd=w,check=True);r=subprocess.run(['git','push','origin','HEAD:refs/heads/scout/indexmaps-snork-replay-20261117'],cwd=w,text=True,capture_output=True,timeout=90);(p/'checkpoint-status.json').write_text(json.dumps({'commit':subprocess.check_output(['git','rev-parse','HEAD'],cwd=w,text=True).strip(),'push_returncode':r.returncode,'push_output':r.stdout+r.stderr},indent=2))
