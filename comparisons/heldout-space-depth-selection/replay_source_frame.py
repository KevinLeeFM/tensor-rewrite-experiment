#!/usr/bin/env python3
"""Fresh offline source-frame and chunk-control build; no target rewrite."""
from pathlib import Path
import datetime,hashlib,json,os,subprocess,tempfile,time
p=Path(__file__).resolve().parent;root=p.parents[1];lean=os.environ.get('LEAN','lean')
v=subprocess.run([lean,'--version'],capture_output=True,text=True,check=True).stdout.strip()
assert 'version 4.35.0,' in v and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in v
files=[('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Tensor.olean'),('TensorRewrite/Pilot/Indexing.lean','TensorRewrite/Pilot/Indexing.olean'),('TensorRewrite/Pilot/Permutation.lean','TensorRewrite/Pilot/Permutation.olean'),('TensorRewrite/Theory/Concatenation.lean','TensorRewrite/Theory/Concatenation.olean'),('TensorRewrite/Theory/ConcatenationLemmas.lean','TensorRewrite/Theory/ConcatenationLemmas.olean'),('comparisons/heldout-space-depth-selection/ShapeBridge.lean','ShapeBridge.olean'),('comparisons/heldout-space-depth-selection/SliceTransport.lean','SliceTransport.olean'),('comparisons/heldout-space-depth-selection/OrderedSlices.lean','OrderedSlices.olean'),('comparisons/heldout-space-depth-selection/ChunkIntervals.lean','ChunkIntervals.olean'),('comparisons/heldout-space-depth-selection/ChunkIntervalsTests.lean','ChunkIntervalsTests.olean'),('comparisons/heldout-space-depth-selection/SourceFrame.lean','SourceFrame.olean'),('comparisons/heldout-space-depth-selection/SourceFrameTests.lean','SourceFrameTests.olean')]
rows=[];start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='source-frame-') as tmp:
 b=Path(tmp);env=os.environ.copy();env['LEAN_PATH']=str(b)
 for src,dst in files:
  f=root/src;out=b/dst;out.parent.mkdir(parents=True,exist_ok=True);t=time.monotonic();r=subprocess.run([lean,str(f),'-o',str(out)],cwd=root,env=env,capture_output=True,text=True,timeout=30)
  rec={'file':src,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'seconds':time.monotonic()-t,'returncode':r.returncode,'output':r.stdout+r.stderr};rows.append(rec)
  assert r.returncode==0 and 'sorryAx' not in rec['output'] and 'warning:' not in rec['output'],rec
  if dst=='SourceFrame.olean':
   lines=rec['output'].splitlines();assert len(lines)==7,lines
   for line in lines:
    if 'does not depend on any axioms' in line:continue
    assert set(x.strip() for x in line.split('[')[-1].rstrip(']').split(',')) <= {'propext','Quot.sound','Classical.choice'},line
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'version':v,'seconds':time.monotonic()-start,'result':'passed','records':rows}
(p/'source-frame-replay.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'result':result['result'],'seconds':result['seconds'],'modules':len(rows),'source_frame':next(x for x in rows if x['file'].endswith('/SourceFrame.lean'))},indent=2))
