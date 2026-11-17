#!/usr/bin/env python3
"""Build old and isolated proposed SliceShape module graphs, offline, without editing sources."""
import hashlib,json,os,pathlib,shutil,subprocess,tempfile,time
root=pathlib.Path(__file__).resolve().parents[2]; here=pathlib.Path(__file__).resolve().parent
lean=os.environ.get('LEAN','lean'); version=subprocess.check_output([lean,'--version'],text=True).strip()
assert '4.35.0' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version,version
orig=(root/'TensorRewrite/Pilot/SliceShape.lean').read_text(); marker='/-- Bound transformation performed on a selected redundant-stride axis;'; first,second=orig.split(marker,1)
proto=here/'prototype/TensorRewrite/Pilot'; end='end TensorRewrite.Pilot.SliceShape\n'
assert (proto/'SliceShapeCore.lean').read_text()==first+'\n'+end
assert (proto/'SliceShapeTransforms.lean').read_text().split('namespace TensorRewrite.Pilot.SliceShape\n\n',1)[1]==marker+second
oldbounds=(root/'TensorRewrite/Pilot/SliceIndexBounds.lean').read_text()
assert (proto/'SliceIndexBounds.lean').read_text()==oldbounds.replace('public import TensorRewrite.Pilot.SliceShape\n','public import TensorRewrite.Pilot.SliceShapeCore\n',1)
protected=['TensorRewrite/Pilot/SliceShape.lean','TensorRewrite/Pilot/SliceIndexBounds.lean','TensorRewrite/Pilot/IndexMaps.lean','TensorRewrite/Pilot/EmptySliceRefutation.lean','comparisons/tensorright-v1/dependency-costs.json','comparisons/tensorright-v1/ReverseSliceFailure.lean']
for p in protected:
 old=subprocess.check_output(['git','show','8ac12787cdb1e106f82b032bca57d18f3ec6752c:'+p],cwd=root)
 assert old==(root/p).read_bytes(),p
records=[]; modes={}; started=time.monotonic()
with tempfile.TemporaryDirectory(prefix='slice-split-') as td:
 for mode in ['original','prototype']:
  w=pathlib.Path(td)/mode; w.mkdir(); env=os.environ.copy();env['LEAN_PATH']=str(w)
  common=['TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/ConstantGuard.lean','TensorRewrite/Pilot/IndexMaps.lean','TensorRewrite/Pilot/EmptySliceRefutation.lean','comparisons/tensorright-v1/ReverseSliceFailure.lean']
  for name in common+['TensorRewrite/Pilot/SliceShape.lean','TensorRewrite/Pilot/SliceIndexBounds.lean']:
   target=w/name;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/name,target)
  if mode=='prototype':
   for f in proto.glob('*.lean'): shutil.copyfile(f,w/'TensorRewrite/Pilot'/f.name)
  def run(source,out=None,fail_marker=None):
   cmd=[lean,source]+(['-o',out] if out else []); start=time.monotonic()
   p=subprocess.run(cmd,cwd=w,env=env,text=True,capture_output=True,timeout=30); output=p.stdout+p.stderr
   records.append({'mode':mode,'source':source,'exit':p.returncode,'seconds':time.monotonic()-start,'expected_failure':fail_marker,'output':output})
   if fail_marker: assert p.returncode!=0 and fail_marker in output,(source,output)
   else: assert p.returncode==0 and 'sorryAx' not in output and 'warning:' not in output,(source,output)
   return output
  modules=['Tensor','ConstantGuard']+(['SliceShapeCore','SliceShapeTransforms','SliceShape'] if mode=='prototype' else ['SliceShape'])+['SliceIndexBounds','IndexMaps','EmptySliceRefutation']
  for module in modules: run('TensorRewrite/Pilot/'+module+'.lean','TensorRewrite/Pilot/'+module+'.olean')
  run('comparisons/tensorright-v1/ReverseSliceFailure.lean','comparisons/tensorright-v1/ReverseSliceFailure.olean')
  (w/'Api.lean').write_text('import TensorRewrite.Pilot.SliceShape\nimport TensorRewrite.Pilot.IndexMaps\nimport TensorRewrite.Pilot.EmptySliceRefutation\nopen TensorRewrite.Pilot.SliceShape\n#print Axis\n#print Axis.elementCount\n#print IsWellFormed\n#print removeRedundantStride\n#print reorderReverse\n#print axioms empty_witness_well_formed\n#print axioms remove_redundant_stride_refutes\n#print axioms reorder_reverse_refutes\nexample : IsWellFormed 4 1 (removeRedundantStride {start := 1, limit := 3, stride := 3}) := by decide\nexample : IsWellFormed 4 1 (reorderReverse 4 {start := 1, limit := 3, stride := 3}) := by decide\n')
  modes[mode]=run('Api.lean')
  (w/'CoreOnly.lean').write_text('import TensorRewrite.Pilot.IndexMaps\n#check TensorRewrite.Pilot.SliceShape.removeRedundantStride\n')
  run('CoreOnly.lean',fail_marker='Unknown identifier' if mode=='prototype' else None)
 assert modes['original']==modes['prototype'],'Printed declaration or axiom report differs'
print(json.dumps({'result':'passed','lean':version,'seconds':time.monotonic()-started,'protected_source_sha256':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in protected},'same_printed_declarations_and_axioms':True,'legacy_facade_compiles':True,'core_only_excludes_rewrite':True,'baseline_core_import_exposed_rewrite':True,'records':records},indent=2))
