#!/usr/bin/env python3
"""Replay the frozen exact goal, source hashes and adversarial controls offline."""
from pathlib import Path
import datetime,hashlib,json,os,subprocess,tempfile,time
p=Path(__file__).resolve().parent;root=p.parents[1];manifest=json.loads((p/'goal-freeze.json').read_text())
for name,expected in manifest['files'].items():
 assert hashlib.sha256((root/name).read_bytes()).hexdigest()==expected, name
lean=os.environ.get('LEAN','lean');version=subprocess.run([lean,'--version'],capture_output=True,text=True,check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
files=[('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Tensor.olean'),('TensorRewrite/Pilot/Indexing.lean','TensorRewrite/Pilot/Indexing.olean'),('TensorRewrite/Pilot/Permutation.lean','TensorRewrite/Pilot/Permutation.olean'),('TensorRewrite/Pilot/FiniteProduct.lean','TensorRewrite/Pilot/FiniteProduct.olean'),('TensorRewrite/Pilot/LinearIndex.lean','TensorRewrite/Pilot/LinearIndex.olean'),('TensorRewrite/Pilot/ConstantGuard.lean','TensorRewrite/Pilot/ConstantGuard.olean'),('TensorRewrite/Pilot/Reshape.lean','TensorRewrite/Pilot/Reshape.olean'),('TensorRewrite/Theory/Concatenation.lean','TensorRewrite/Theory/Concatenation.olean'),('TensorRewrite/Theory/ConcatenationLemmas.lean','TensorRewrite/Theory/ConcatenationLemmas.olean')]
for name in ['ShapeBridge','SliceTransport','OrderedSlices','ChunkIntervals','SourceFrame','ElementCount','GoalCandidate','GoalCandidateGuard','GoalCandidateBasis','ElementCountTests','ChunkIntervalsTests','SourceFrameTests','GoalCandidateTests']:
 files.append((f'comparisons/heldout-space-depth-selection/{name}.lean',f'{name}.olean'))
rows=[];start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='frozen-goal-') as tmp:
 b=Path(tmp);env=os.environ.copy();env['LEAN_PATH']=str(b)
 def run(src,dst=None,expected=None,negative=False):
  f=root/src;argv=[lean,str(f)];out=(b/'negative'/dst if negative else b/dst) if dst else None
  if out:out.parent.mkdir(parents=True,exist_ok=True);argv+=['-o',str(out)]
  e=env.copy()
  if negative:e['LEAN_PATH']=str(b/'negative')+os.pathsep+str(b)
  t=time.monotonic();r=subprocess.run(argv,cwd=root,env=e,capture_output=True,text=True,timeout=30)
  rec={'file':src,'seconds':time.monotonic()-t,'returncode':r.returncode,'output':r.stdout+r.stderr,'expected_failure':expected};rows.append(rec)
  if expected:assert r.returncode!=0 and expected in rec['output'],rec
  else:assert r.returncode==0 and 'sorryAx' not in rec['output'] and 'warning:' not in rec['output'],rec
  if dst in ['ElementCount.olean','GoalCandidate.olean']:
   for line in rec['output'].splitlines():
    if 'does not depend on any axioms' in line:continue
    assert 'depends on axioms: [' in line,line
    assert set(x.strip() for x in line.split('[')[-1].rstrip(']').split(',')) <= {'propext','Quot.sound','Classical.choice'},line
 for src,dst in files:run(src,dst)
 run('comparisons/heldout-unit-reverse-v1/controls/Forbidden.lean','Forbidden.olean',negative=True)
 run('comparisons/heldout-space-depth-selection/GoalCandidateLeak.lean',expected='CANDIDATE_BASELINE_LEAK',negative=True)
 run('comparisons/heldout-space-depth-selection/GoalCandidateSignatureNegative.lean',expected='CANDIDATE_SIGNATURE_MISMATCH')
result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'version':version,'seconds':time.monotonic()-start,'result':'passed','records':rows}
(p/'goal-replay.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps({'utc':result['utc'],'seconds':result['seconds'],'modules':len(rows),'result':result['result'],'controls':rows[-2:]},indent=2))
