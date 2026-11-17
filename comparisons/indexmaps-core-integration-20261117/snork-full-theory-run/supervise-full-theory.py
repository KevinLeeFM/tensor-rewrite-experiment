import subprocess,json,time,shutil,os,pathlib
p=pathlib.Path('/tmp/scout-tensor-indexmaps-replay-20261117');d=json.load(open(p/'theory-nobuild-user-receipt.json'));cmd=d['command'];cmd[2:2]=['--name','scout-tensor-full-theory-20261117'];cmd[-1]='export PATH=/toolchain/bin:$PATH; lean --version; python3 tools/check_theory.py';start=time.time();out=open(p/'full-theory.stdout.txt','w');err=open(p/'full-theory.stderr.txt','w');proc=subprocess.Popen(cmd,stdout=out,stderr=err);samples=[];stop=None
while proc.poll() is None:
 free=shutil.disk_usage('/tmp').free;elapsed=time.time()-start;samples.append({'seconds':elapsed,'free_bytes':free});(p/'full-theory-progress.json').write_text(json.dumps({'pid':proc.pid,'elapsed_seconds':elapsed,'free_bytes':free,'needs_supervision':elapsed>=600,'samples':samples},indent=2))
 if free<5500000000:
  stop='free disk safety floor approached';subprocess.run(['docker','stop','-t','10','scout-tensor-full-theory-20261117'],capture_output=True);break
 time.sleep(10)
rc=proc.wait();out.close();err.close();(p/'full-theory-receipt.json').write_text(json.dumps({'command':cmd,'returncode':rc,'elapsed_seconds':time.time()-start,'stop_reason':stop,'disk_samples':samples,'source_commit':'938b193d4fadbd5e3209b775a88823b9d114715e','approval':'Kevin: I approve that. Full 242 local modules/727 declarations, isolated offline read-only cache,2CPU/2GB,10min supervision,5GB free-disk stop floor.'},indent=2))
