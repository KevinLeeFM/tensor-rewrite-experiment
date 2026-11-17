#!/usr/bin/env python3
"""Focused old-vs-integrated import and statement replay; not a full theory build."""
import hashlib,json,os,pathlib,subprocess,tempfile,time
root=pathlib.Path(__file__).resolve().parents[2]; base='28b4bf12be2f2252d6422270b0927d5aed631ac6'; lean=os.environ.get('LEAN','lean'); v=subprocess.check_output([lean,'--version'],text=True).strip();assert '4.35.0' in v and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in v
names=['Tensor','Indexing','ConstantGuard','ConstantGuardLemmas','SliceShape','SliceIndexBounds','IndexMaps','IndexMapLemmas','EmptySliceRefutation']; added=['SliceShapeCore','SliceShapeTransforms','SliceIndexBoundsCore','IndexMapsCore']; paper=['Iota','ReverseSliceFailure'];
def old(path):return subprocess.check_output(['git','show',base+':'+path],cwd=root)
legacy_index=old('TensorRewrite/Pilot/IndexMaps.lean').decode(); integrated=(root/'TensorRewrite/Pilot/IndexMapsCore.lean').read_text()
assert integrated==legacy_index.replace('public import TensorRewrite.Pilot.SliceIndexBounds\n','public import TensorRewrite.Pilot.SliceIndexBoundsCore\n',1)
legacy_shape=old('TensorRewrite/Pilot/SliceShape.lean').decode();marker='/-- Bound transformation performed on a selected redundant-stride axis;';a,b=legacy_shape.split(marker,1);p=root/'TensorRewrite/Pilot'
assert (p/'SliceShapeCore.lean').read_text()==a+'\nend TensorRewrite.Pilot.SliceShape\n'
assert (p/'SliceShapeTransforms.lean').read_text().split('namespace TensorRewrite.Pilot.SliceShape\n\n',1)[1]==marker+b
assert (p/'SliceIndexBoundsCore.lean').read_text()==old('TensorRewrite/Pilot/SliceIndexBounds.lean').decode().replace('public import TensorRewrite.Pilot.SliceShape\n','public import TensorRewrite.Pilot.SliceShapeCore\n',1)
cases=json.loads((root/'comparisons/tensorright-v1/cases.json').read_text())['cases'];assert len(cases)==118
for c in cases:
 f=root/c['lean_proof_file'];assert hashlib.sha256(f.read_bytes()).hexdigest()==c['lean_proof_sha256'],str(f)
heldout=['comparisons/heldout-unit-reverse-v1/Spec.lean','comparisons/heldout-transpose-broadcast/Spec.lean','comparisons/heldout-dynamic-unit/Spec.lean','comparisons/heldout-dynamic-transpose/Spec.lean']
for name in heldout: assert (root/name).read_bytes()==old(name),name
historical=json.loads((root/'comparisons/tensorright-v1/dependency-costs.json').read_text()); mismatches=[x['path'] for x in historical['files'] if hashlib.sha256((root/x['path']).read_bytes()).hexdigest()!=x['sha256']]
assert set(mismatches)=={'TensorRewrite/Pilot/IndexMaps.lean','TensorRewrite/Pilot/SliceIndexBounds.lean','TensorRewrite/Pilot/SliceShape.lean'},mismatches
records=[];printed={};start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='indexmaps-core-') as td:
 for mode in ['baseline','integration']:
  w=pathlib.Path(td)/mode;w.mkdir();env=os.environ.copy();env['LEAN_PATH']=str(w)
  for n in names:
   name='TensorRewrite/Pilot/'+n+'.lean';target=w/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(old(name) if mode=='baseline' else (root/name).read_bytes())
  if mode=='integration':
   for n in added:
    name='TensorRewrite/Pilot/'+n+'.lean';(w/name).write_bytes((root/name).read_bytes())
  for n in paper:
   name='comparisons/tensorright-v1/'+n+'.lean';target=w/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes((root/name).read_bytes())
  def run(src,out=None,marker=None):
   t=time.monotonic();p=subprocess.run([lean,src]+(['-o',out] if out else []),cwd=w,env=env,text=True,capture_output=True,timeout=30);o=p.stdout+p.stderr
   records.append({'mode':mode,'source':src,'exit':p.returncode,'seconds':time.monotonic()-t,'expected_failure':marker,'output':o})
   if marker:assert p.returncode!=0 and marker in o,(src,o)
   else:assert p.returncode==0 and 'sorryAx' not in o and 'warning:' not in o,(src,o)
   return o
  order=['Tensor','Indexing','ConstantGuard','ConstantGuardLemmas']+(['SliceShapeCore','SliceShapeTransforms','SliceShape','SliceIndexBoundsCore','SliceIndexBounds','IndexMapsCore','IndexMaps'] if mode=='integration' else ['SliceShape','SliceIndexBounds','IndexMaps'])+['IndexMapLemmas','EmptySliceRefutation']
  for n in order:run('TensorRewrite/Pilot/'+n+'.lean','TensorRewrite/Pilot/'+n+'.olean')
  for n in paper:run('comparisons/tensorright-v1/'+n+'.lean','comparisons/tensorright-v1/'+n+'.olean')
  (w/'Print.lean').write_text('import TensorRewrite.Pilot.IndexMapLemmas\nimport TensorRewrite.Pilot.EmptySliceRefutation\nopen TensorRewrite.Pilot\n#print SliceShape.Axis\n#print SliceShape.IsWellFormed\n#print SliceShape.removeRedundantStride\n#print SliceShape.reorderReverse\n#print SliceShape.coordinate_bounds\n#print IndexMaps.BroadcastAxes\n#print IndexMaps.broadcastIndex\n#print IndexMaps.sliceIndex\n#print IndexMaps.broadcastView\n#print IndexMaps.sliceView\n#print axioms IndexMaps.sliceIndex_val\n#print axioms SliceShape.remove_redundant_stride_refutes\n#print axioms SliceShape.reorder_reverse_refutes\n')
  printed[mode]=run('Print.lean')
  (w/'Legacy.lean').write_text('import TensorRewrite.Pilot.IndexMaps\n#check TensorRewrite.Pilot.SliceShape.removeRedundantStride\n#check TensorRewrite.Pilot.SliceShape.reorderReverse\n#check TensorRewrite.Pilot.IndexMaps.sliceIndex\n')
  run('Legacy.lean')
  if mode=='integration':
   (w/'Clean.lean').write_text('import TensorRewrite.Pilot.IndexMapsCore\n#check TensorRewrite.Pilot.IndexMaps.sliceIndex\n#check TensorRewrite.Pilot.SliceShape.coordinate_bounds\n');run('Clean.lean')
   for n in ['removeRedundantStride','reorderReverse']:
    (w/'NoRewrite.lean').write_text('import TensorRewrite.Pilot.IndexMapsCore\n#check TensorRewrite.Pilot.SliceShape.'+n+'\n');run('NoRewrite.lean',marker='Unknown identifier')
   for n,imps in [('MixedCoreFirst',['TensorRewrite.Pilot.IndexMapsCore','TensorRewrite.Pilot.IndexMaps']),('MixedLegacyFirst',['TensorRewrite.Pilot.IndexMaps','TensorRewrite.Pilot.IndexMapsCore'])]:
    (w/(n+'.lean')).write_text(''.join('import '+i+'\n' for i in imps)+'#check TensorRewrite.Pilot.IndexMaps.sliceIndex\n#check TensorRewrite.Pilot.SliceShape.reorderReverse\n');run(n+'.lean')
 assert printed['baseline']==printed['integration'],'printed declarations or axioms differ'
print(json.dumps({'result':'passed_focused_not_full_integration','lean':v,'seconds':time.monotonic()-start,'paper_statement_hashes_checked':len(cases),'heldout_statement_hashes_checked':heldout,'historical_source_hash_mismatches_expected':mismatches,'source_body_checks':'passed','selected_prints_and_axioms_match':True,'legacy_api':'passed','clean_core_negative_controls':'passed','mixed_import_orders':'passed','records':records},indent=2))
