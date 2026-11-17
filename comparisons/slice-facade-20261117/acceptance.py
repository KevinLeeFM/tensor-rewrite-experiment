#!/usr/bin/env python3
"""Compare frozen source and an isolated backwards-compatible facade prototype."""
import hashlib,json,os,pathlib,shutil,subprocess,tempfile,time
root=pathlib.Path(__file__).resolve().parents[2]; here=pathlib.Path(__file__).resolve().parent
lean=os.environ.get('LEAN','lean'); version=subprocess.check_output([lean,'--version'],text=True).strip()
assert '4.35.0' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
orig=(root/'TensorRewrite/Pilot/SliceShape.lean').read_text();marker='/-- Bound transformation performed on a selected redundant-stride axis;';first,second=orig.split(marker,1)
proto=here/'prototype/TensorRewrite/Pilot';end='end TensorRewrite.Pilot.SliceShape\n'
assert (proto/'SliceShapeCore.lean').read_text()==first+'\n'+end
assert (proto/'SliceShapeTransforms.lean').read_text().split('namespace TensorRewrite.Pilot.SliceShape\n\n',1)[1]==marker+second
bounds=(root/'TensorRewrite/Pilot/SliceIndexBounds.lean').read_text()
assert (proto/'SliceIndexBoundsCore.lean').read_text()==bounds.replace('public import TensorRewrite.Pilot.SliceShape\n','public import TensorRewrite.Pilot.SliceShapeCore\n',1)
protected=['TensorRewrite/Pilot/SliceShape.lean','TensorRewrite/Pilot/SliceIndexBounds.lean','TensorRewrite/Pilot/IndexMaps.lean','TensorRewrite/Pilot/IndexMapLemmas.lean','TensorRewrite/Pilot/EmptySliceRefutation.lean','comparisons/tensorright-v1/Iota.lean','comparisons/tensorright-v1/ReverseSliceFailure.lean','comparisons/tensorright-v1/dependency-costs.json']
for p in protected:
 assert subprocess.check_output(['git','show','27ae22bfbc3982b6f31eda34fcc21d83db96c6f8:'+p],cwd=root)==(root/p).read_bytes(),p
records=[]; modes={}; started=time.monotonic()
with tempfile.TemporaryDirectory(prefix='slice-facade-') as td:
 for mode in ['original','prototype']:
  w=pathlib.Path(td)/mode; w.mkdir(); env=os.environ.copy();env['LEAN_PATH']=str(w)
  modules=['Tensor','Indexing','ConstantGuard','ConstantGuardLemmas','SliceShape','SliceIndexBounds','IndexMaps','IndexMapLemmas','EmptySliceRefutation']
  if mode=='prototype': modules=['Tensor','Indexing','ConstantGuard','ConstantGuardLemmas','SliceShapeCore','SliceShapeTransforms','SliceShape','SliceIndexBoundsCore','SliceIndexBounds','IndexMaps','IndexMapLemmas','EmptySliceRefutation']
  for name in ['Tensor','Indexing','ConstantGuard','ConstantGuardLemmas','SliceShape','SliceIndexBounds','IndexMaps','IndexMapLemmas','EmptySliceRefutation']:
   path='TensorRewrite/Pilot/'+name+'.lean'; target=w/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/path,target)
  for n in ['Iota','ReverseSliceFailure']:
   path='comparisons/tensorright-v1/'+n+'.lean';target=w/path;target.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(root/path,target)
  if mode=='prototype':
   for f in proto.glob('*.lean'): shutil.copyfile(f,w/'TensorRewrite/Pilot'/f.name)
  def run(source,out=None,marker=None):
   start=time.monotonic();p=subprocess.run([lean,source]+(['-o',out] if out else []),cwd=w,env=env,text=True,capture_output=True,timeout=30);output=p.stdout+p.stderr
   records.append({'mode':mode,'source':source,'exit':p.returncode,'seconds':time.monotonic()-start,'expected_failure':marker,'output':output})
   if marker: assert p.returncode!=0 and marker in output,(source,output)
   else: assert p.returncode==0 and 'sorryAx' not in output and 'warning:' not in output,(source,output)
   return output
  for m in modules: run('TensorRewrite/Pilot/'+m+'.lean','TensorRewrite/Pilot/'+m+'.olean')
  for n in ['Iota','ReverseSliceFailure']: run('comparisons/tensorright-v1/'+n+'.lean','comparisons/tensorright-v1/'+n+'.olean')
  (w/'Api.lean').write_text('import TensorRewrite.Pilot.IndexMapLemmas\nimport TensorRewrite.Pilot.EmptySliceRefutation\nopen TensorRewrite.Pilot.SliceShape\n#print Axis\n#print Axis.elementCount\n#print IsWellFormed\n#print removeRedundantStride\n#print reorderReverse\n#print coordinate_bounds\n#print axioms coordinate_bounds\n#print axioms remove_redundant_stride_refutes\n#print axioms reorder_reverse_refutes\n#print axioms TensorRewrite.Pilot.IndexMaps.sliceIndex_val\nexample : IsWellFormed 4 1 (removeRedundantStride {start := 1, limit := 3, stride := 3}) := by decide\nexample : IsWellFormed 4 1 (reorderReverse 4 {start := 1, limit := 3, stride := 3}) := by decide\n')
  modes[mode]=run('Api.lean')
  for n,imp in [('LegacyBounds','TensorRewrite.Pilot.SliceIndexBounds'),('LegacyIndex','TensorRewrite.Pilot.IndexMaps')]:
   (w/(n+'.lean')).write_text('import '+imp+'\n#check TensorRewrite.Pilot.SliceShape.removeRedundantStride\n#check TensorRewrite.Pilot.SliceShape.reorderReverse\n#check TensorRewrite.Pilot.SliceShape.coordinate_bounds\n')
   run(n+'.lean')
  if mode=='prototype':
   (w/'CorePositive.lean').write_text('import TensorRewrite.Pilot.SliceIndexBoundsCore\n#check TensorRewrite.Pilot.SliceShape.coordinate_bounds\n')
   run('CorePositive.lean')
   (w/'CoreNegative.lean').write_text('import TensorRewrite.Pilot.SliceIndexBoundsCore\n#check TensorRewrite.Pilot.SliceShape.removeRedundantStride\n')
   run('CoreNegative.lean',marker='Unknown identifier')
   for n,imps in [('MixedCoreFirst',['TensorRewrite.Pilot.SliceIndexBoundsCore','TensorRewrite.Pilot.IndexMaps']),('MixedLegacyFirst',['TensorRewrite.Pilot.IndexMaps','TensorRewrite.Pilot.SliceIndexBoundsCore'])]:
    (w/(n+'.lean')).write_text(''.join('import '+i+'\n' for i in imps)+'#check TensorRewrite.Pilot.SliceShape.coordinate_bounds\n#check TensorRewrite.Pilot.SliceShape.removeRedundantStride\n')
    run(n+'.lean')
 assert modes['original']==modes['prototype'],'Printed declarations or axiom report changed'
print(json.dumps({'result':'passed','lean':version,'seconds':time.monotonic()-started,'same_printed_declarations_and_axioms':True,'legacy_bounds_and_index_transitive_api':True,'opt_in_bounds_core_excludes_transforms':True,'mixed_import_orders':True,'protected_source_sha256':{p:hashlib.sha256((root/p).read_bytes()).hexdigest() for p in protected},'records':records},indent=2))
