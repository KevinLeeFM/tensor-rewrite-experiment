from pathlib import Path
import re,sys,os,subprocess,hashlib,time
root=Path.cwd(); packet=Path('comparisons/revised-benchmark-20261117/slice-update')
out=Path(os.environ.get('BUILD','/tmp/slicedus-build')); out.mkdir(exist_ok=True)
seq={}
def walk(m):
 if m in seq:return
 p=Path(m.replace('.','/')+'.lean')
 if not p.exists():p=packet/(m+'.lean')
 for im in re.findall(r'^(?:public )?import ([\w.]+)',p.read_text(),re.M):
  if im!='Std':walk(im)
 seq[m]=p
walk(sys.argv[1])
if len(sys.argv)>2:
 with (packet/'SHA256SUMS').open('w') as f:
  for p in [*seq.values(),Path('sources/xla/xla/hlo/transforms/simplifiers/algebraic_simplifier.cc'),Path('lean-toolchain')]:
   print(hashlib.sha256(p.read_bytes()).hexdigest(),p,file=f)
for m,p in seq.items():
 target=out/(m.replace('.','/')+'.olean'); target.parent.mkdir(exist_ok=True,parents=True)
 if target.exists() and target.stat().st_mtime>p.stat().st_mtime:continue
 t=time.monotonic(); proc=subprocess.run(['/workspace/toolchains/lean-4.35.0-linux/bin/lean','-o',str(target),str(p)],env={**os.environ,'LEAN_PATH':str(out)})
 print(m,round(time.monotonic()-t,3),proc.returncode,flush=True)
 if proc.returncode:sys.exit(1)
