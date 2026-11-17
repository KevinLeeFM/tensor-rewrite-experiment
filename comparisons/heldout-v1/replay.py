#!/usr/bin/env python3
"""Replay the frozen smoke test only; no Lake update/build or downloads."""
from pathlib import Path
import hashlib,json,os,subprocess,time
root=Path(__file__).resolve().parents[2];p=Path(__file__).resolve().parent
m=json.loads((p/'frozen-manifest.json').read_text())
assert hashlib.sha256((p/'Spec.lean').read_bytes()).hexdigest()==m['spec_sha256']
for x in m['custom_modules']:
 assert hashlib.sha256((root/x['file']).read_bytes()).hexdigest()==x['sha256']
lib=p/'build';lib.mkdir(exist_ok=True);env=os.environ.copy();env['LEAN_PATH']=str(lib)
lean=os.environ.get('LEAN','lean');records=[]
files=[root/f'TensorRewrite/Pilot/{n}.lean' for n in ['Tensor','Indexing','Permutation','FiniteProduct','FiniteProductLemmas']]+[p/f'{n}.lean' for n in ['Spec','Proof','Audit']]
for f in files:
 rel=f.relative_to(root) if f.parent!=p else Path(f.name)
 out=lib/rel.with_suffix('.olean');out.parent.mkdir(parents=True,exist_ok=True)
 t=time.monotonic();r=subprocess.run([lean,str(f),'-o',str(out)],cwd=root,env=env,capture_output=True,text=True,timeout=30)
 records.append(dict(file=str(rel),seconds=time.monotonic()-t,returncode=r.returncode,output=r.stdout+r.stderr))
 if r.returncode:print(json.dumps(records,indent=2));raise SystemExit(r.returncode)
print(json.dumps(records,indent=2))
