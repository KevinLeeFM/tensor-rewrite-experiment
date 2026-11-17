#!/usr/bin/env python3
"""Fresh offline generic element-count partial results; no rewrite proof."""
from pathlib import Path
import datetime,hashlib,json,os,subprocess,tempfile,time
p=Path(__file__).resolve().parent;root=p.parents[1];lean=os.environ.get('LEAN','lean')
v=subprocess.run([lean,'--version'],capture_output=True,text=True,check=True).stdout.strip()
assert 'version 4.35.0,' in v and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in v
files=[('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Tensor.olean'),('TensorRewrite/Pilot/FiniteProduct.lean','TensorRewrite/Pilot/FiniteProduct.olean'),('TensorRewrite/Pilot/Indexing.lean','TensorRewrite/Pilot/Indexing.olean'),('TensorRewrite/Pilot/Permutation.lean','TensorRewrite/Pilot/Permutation.olean'),('TensorRewrite/Pilot/LinearIndex.lean','TensorRewrite/Pilot/LinearIndex.olean'),('comparisons/heldout-space-depth-selection/ShapeBridge.lean','ShapeBridge.olean'),('comparisons/heldout-space-depth-selection/ElementCount.lean','ElementCount.olean'),('comparisons/heldout-space-depth-selection/ElementCountTests.lean','ElementCountTests.olean')]
rows=[];t0=time.monotonic()
with tempfile.TemporaryDirectory(prefix='element-count-') as tmp:
 b=Path(tmp);env=os.environ.copy();env['LEAN_PATH']=str(b)
 for src,dst in files:
  f=root/src;out=b/dst;out.parent.mkdir(parents=True,exist_ok=True);t=time.monotonic();r=subprocess.run([lean,str(f),'-o',str(out)],cwd=root,env=env,capture_output=True,text=True,timeout=30)
  x={'file':src,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'seconds':time.monotonic()-t,'returncode':r.returncode,'output':r.stdout+r.stderr};rows.append(x)
  assert r.returncode==0 and 'sorryAx' not in x['output'] and 'warning:' not in x['output'],x
  if dst=='ElementCount.olean':
   lines=x['output'].splitlines();assert len(lines)==5,lines
   for line in lines:assert set(a.strip() for a in line.split('[')[-1].rstrip(']').split(',')) <= {'propext','Quot.sound','Classical.choice'},line
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'version':v,'seconds':time.monotonic()-t0,'result':'passed','records':rows}
(p/'element-replay.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'utc':result['utc'],'result':result['result'],'seconds':result['seconds'],'modules':len(rows),'element_output':rows[-2]['output']},indent=2))
