import os, pathlib, subprocess, tempfile, time, hashlib, json, datetime
root=pathlib.Path.cwd();base='comparisons/heldout-space-depth-selection/';manifest=json.loads((root/base/'goal-freeze.json').read_text());bad=[n for n,h in manifest['files'].items() if hashlib.sha256((root/n).read_bytes()).hexdigest()!=h];assert not bad,bad
files=[('TensorRewrite/Pilot/'+n+'.lean','TensorRewrite/Pilot/'+n+'.olean') for n in ['Tensor','Indexing','Permutation','FiniteProduct','LinearIndex','ConstantGuard','Reshape','FiniteProductLemmas','LinearIndexLemmas']]
files += [('TensorRewrite/Theory/'+n+'.lean','TensorRewrite/Theory/'+n+'.olean') for n in ['Concatenation','ConcatenationLemmas']]
files += [(base+n+'.lean',n+'.olean') for n in ['ShapeBridge','SliceTransport','OrderedSlices','ChunkIntervals','SourceFrame','ElementCount','GoalCandidate','CoordinateBridge','CoordinateChunkAdapter','IndexTransportAttempt','CoordinateBridgeTests']]
lean='/workspace/toolchains/lean-4.35.0-linux/bin/lean'; rows=[]; start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='index-transport-') as temp:
 env=os.environ.copy();env['LEAN_PATH']=temp
 for src,out in files:
  target=pathlib.Path(temp)/out;target.parent.mkdir(parents=True,exist_ok=True);now=time.monotonic(); p=subprocess.run([lean,src,'-o',str(target)],cwd=root,env=env,text=True,capture_output=True); result=p.stdout+p.stderr;rows.append({'source':src,'seconds':round(time.monotonic()-now,4),'exit':p.returncode,'output':result});print(src,p.returncode,flush=True);assert p.returncode==0 and 'sorryAx' not in result and 'warning:' not in result,result
 text=(root/base/'GoalCandidateTests.lean').read_text().replace('import GoalCandidate','import GoalCandidate\nimport IndexTransportAttempt',1)
 text+='\nnamespace Heldout.SpaceDepthCandidate.Tests\nopen Heldout.IndexTransportAttempt\n'
 for i,v in [(0,0),(1,0),(2,3)]:
  text+=f'example : (originalIndex nonemptyPlan outIndex ⟨{i}, by decide⟩).val = {v} := by decide\n'
  text+=f'example : (replacementIndex nonemptyPlan linearInput outIndex ⟨{i}, by decide⟩).val = {v} := by decide\n'
 text+='end Heldout.SpaceDepthCandidate.Tests\n'; (pathlib.Path(temp)/'Concrete.lean').write_text(text)
 now=time.monotonic();p=subprocess.run([lean,str(pathlib.Path(temp)/'Concrete.lean')],cwd=root,env=env,text=True,capture_output=True);rows.append({'source':'isolated GoalCandidateTests plus six concrete index controls','seconds':round(time.monotonic()-now,4),'exit':p.returncode,'output':p.stdout+p.stderr});assert p.returncode==0 and 'warning:' not in p.stdout+p.stderr,p.stdout+p.stderr
 result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'lean':subprocess.check_output([lean,'--version'],text=True).strip(),'replay_seconds':round(time.monotonic()-start,3),'frozen_hash_count':len(manifest['files']),'mismatches':bad,'candidate_hash':hashlib.sha256((root/base/'IndexTransportAttempt.lean').read_bytes()).hexdigest(),'files':rows};(root/base/'index-transport-replay.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS',result['replay_seconds'])
