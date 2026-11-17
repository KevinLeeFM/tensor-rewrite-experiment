import os, pathlib, subprocess, tempfile, time, hashlib, json, datetime
root=pathlib.Path.cwd();base='comparisons/heldout-space-depth-selection/';manifest=json.loads((root/base/'goal-freeze.json').read_text());bad=[n for n,h in manifest['files'].items() if hashlib.sha256((root/n).read_bytes()).hexdigest()!=h];assert not bad,bad
freeze=json.loads((root/base/'recursive-decomposition-freeze.json').read_text());bad2=[n for n,h in freeze['files'].items() if hashlib.sha256((root/n).read_bytes()).hexdigest()!=h];assert not bad2,bad2
files=[('TensorRewrite/Pilot/'+n+'.lean','TensorRewrite/Pilot/'+n+'.olean') for n in ['Tensor','Indexing','Permutation','FiniteProduct','LinearIndex','ConstantGuard','Reshape','FiniteProductLemmas','LinearIndexLemmas']]
files += [('TensorRewrite/Theory/'+n+'.lean','TensorRewrite/Theory/'+n+'.olean') for n in ['Concatenation','ConcatenationLemmas']]
files += [(base+n+'.lean',n+'.olean') for n in ['ShapeBridge','SliceTransport','OrderedSlices','ChunkIntervals','SourceFrame','ElementCount','GoalCandidate','CoordinateBridge','CoordinateChunkAdapter','IndexTransportAttempt','CoordinateBridgeTests','ProductAssociation','ContextAssociation','PermutationCoordinate','PermutationRegions','ContextAssociationTests','RecursiveShapeSplit','PlanShapeSplit','RecursiveShapeSplitTests','OriginalSplitConnection']]
lean='/workspace/toolchains/lean-4.35.0-linux/bin/lean'; rows=[]; start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='index-transport-') as temp:
 env=os.environ.copy();env['LEAN_PATH']=temp
 for src,out in files:
  target=pathlib.Path(temp)/out;target.parent.mkdir(parents=True,exist_ok=True);now=time.monotonic(); p=subprocess.run([lean,src,'-o',str(target)],cwd=root,env=env,text=True,capture_output=True); result=p.stdout+p.stderr;rows.append({'source':src,'seconds':round(time.monotonic()-now,4),'exit':p.returncode,'output':result});print(src,p.returncode,flush=True);assert p.returncode==0 and 'sorryAx' not in result and 'warning:' not in result,result
 text=(root/base/'GoalCandidateTests.lean').read_text().replace('import GoalCandidate','import GoalCandidate\nimport IndexTransportAttempt\nimport PermutationCoordinate\nimport PermutationRegions\nimport PlanShapeSplit\nimport OriginalSplitConnection',1)
 text+='\nnamespace Heldout.SpaceDepthCandidate.Tests\nopen Heldout.IndexTransportAttempt\n'
 for i,v in [(0,0),(1,0),(2,3)]:
  text+=f'example : (originalIndex nonemptyPlan outIndex ⟨{i}, by decide⟩).val = {v} := by decide\n'
  text+=f'example : (replacementIndex nonemptyPlan linearInput outIndex ⟨{i}, by decide⟩).val = {v} := by decide\n'
 text+='example : plan.permutation.inputToOutput plan.split.succ = plan.split.succ := Heldout.PermutationCoordinate.width_inverse plan\n'
 text+='example : plan.permutation.inputToOutput plan.split.castSucc = plan.moved := Heldout.PermutationCoordinate.selected_inverse plan\n'
 text+='example : (plan.permutation.outputToInput ⟨0, by decide⟩).val = 0 := Heldout.PermutationRegions.before_moved plan ⟨0, by decide⟩ (by decide)\n'
 text+='example : (plan.permutation.outputToInput ⟨2, by decide⟩).val + 1 = 2 := Heldout.PermutationRegions.between_moved_split plan ⟨2, by decide⟩ (by decide) (by decide)\n'
 text+='example : (plan.permutation.outputToInput ⟨3, by decide⟩).val = 3 := Heldout.PermutationRegions.after_split plan ⟨3, by decide⟩ (by decide)\n'
 text+='example := Heldout.PlanShapeSplit.plan_count_split plan inner\n'
 text+='example (index : Index (transposedShape inner plan.permutation)) := Heldout.PlanShapeSplit.plan_index_split plan inner index\n'
 text+='example := Heldout.OriginalSplitConnection.outer_positions_equal nonemptyPlan linearInput outIndex\n'
 text+='example := Heldout.OriginalSplitConnection.outer_packed_parts_equal nonemptyPlan linearInput outIndex\n'
 text+='end Heldout.SpaceDepthCandidate.Tests\n'; (pathlib.Path(temp)/'Concrete.lean').write_text(text)
 now=time.monotonic();p=subprocess.run([lean,str(pathlib.Path(temp)/'Concrete.lean')],cwd=root,env=env,text=True,capture_output=True);rows.append({'source':'isolated GoalCandidateTests plus six concrete index controls and five permutation checks','seconds':round(time.monotonic()-now,4),'exit':p.returncode,'output':p.stdout+p.stderr});assert p.returncode==0 and 'warning:' not in p.stdout+p.stderr,p.stdout+p.stderr
 result={'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'lean':subprocess.check_output([lean,'--version'],text=True).strip(),'replay_seconds':round(time.monotonic()-start,3),'frozen_hash_count':len(manifest['files']),'mismatches':bad,'separate_freeze_count':len(freeze['files']),'separate_freeze_mismatches':bad2,'candidate_hashes':{n:hashlib.sha256((root/base/n).read_bytes()).hexdigest() for n in ['ContextAssociation.lean','ContextAssociationTests.lean','PermutationCoordinate.lean','PermutationRegions.lean','RecursiveShapeSplit.lean','PlanShapeSplit.lean','RecursiveShapeSplitTests.lean','OriginalSplitConnection.lean']},'files':rows};(root/base/'original-split-connection-replay.json').write_text(json.dumps(result,indent=2)+'\n');print('PASS',result['replay_seconds'])
