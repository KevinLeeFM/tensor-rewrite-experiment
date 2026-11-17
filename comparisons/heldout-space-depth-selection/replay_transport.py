#!/usr/bin/env python3
"""Rebuild only the generic single-slice transport and its controls offline."""
from pathlib import Path
import datetime, hashlib, json, os, subprocess, tempfile, time
p=Path(__file__).resolve().parent; root=p.parents[1]; m=json.loads((p/'ALLOWED-IMPORTS.json').read_text())
for record in m['modules']:
 if record['path'] in ('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Theory/Concatenation.lean'):
  assert hashlib.sha256((root/record['path']).read_bytes()).hexdigest()==record['sha256'],record['path']
lean=os.environ.get('LEAN','lean');version=subprocess.run([lean,'--version'],capture_output=True,text=True,check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
results=[];start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='slice-transport-') as temporary:
 b=Path(temporary);env=os.environ.copy();env['LEAN_PATH']=str(b)
 for src,dest in [('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Tensor.olean'),('TensorRewrite/Theory/Concatenation.lean','TensorRewrite/Theory/Concatenation.olean'),('comparisons/heldout-space-depth-selection/SliceTransport.lean','SliceTransport.olean'),('comparisons/heldout-space-depth-selection/SliceTransportTests.lean','SliceTransportTests.olean')]:
  out=b/dest;out.parent.mkdir(parents=True,exist_ok=True);t=time.monotonic()
  r=subprocess.run([lean,str(root/src),'-o',str(out)],cwd=root,env=env,capture_output=True,text=True,timeout=30)
  row={'file':src,'seconds':time.monotonic()-t,'returncode':r.returncode,'output':r.stdout+r.stderr};results.append(row)
  assert r.returncode==0 and 'sorryAx' not in row['output'],row
  if dest=='SliceTransport.olean':
   assert all(a.strip() in {'propext','Quot.sound','Classical.choice'} for line in row['output'].splitlines() for a in line.split('[')[-1].rstrip(']').split(',')),row
result={'checked_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'compiler':version,'seconds':time.monotonic()-start,'files':results,'result':'passed'}
(p/'transport-replay.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))
