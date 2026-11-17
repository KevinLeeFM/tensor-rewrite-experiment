#!/usr/bin/env python3
"""Replay the other Std-only paper target transitively importing IndexMaps."""
import json,os,pathlib,subprocess,tempfile,time
root=pathlib.Path(__file__).resolve().parents[2];base='28b4bf12be2f2252d6422270b0927d5aed631ac6';lean=os.environ.get('LEAN','lean'); v=subprocess.check_output([lean,'--version'],text=True).strip();assert '4.35.0' in v and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in v
names=['Tensor','ConstantGuard','SliceShape','SliceIndexBounds','IndexMaps']; extra=['SliceShapeCore','SliceShapeTransforms','SliceIndexBoundsCore','IndexMapsCore']; rest=['TensorRewrite/Theory/ControlValues.lean','TensorRewrite/Theory/ControlValuesProof.lean','comparisons/tensorright-v1/Select.lean']; rows=[];result={};start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='indexmaps-select-') as td:
 for mode in ['baseline','integration']:
  w=pathlib.Path(td)/mode;w.mkdir();env=os.environ.copy();env['LEAN_PATH']=str(w)
  def copy(name,baseline=True):
   target=w/name;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(subprocess.check_output(['git','show',base+':'+name],cwd=root) if mode=='baseline' and baseline else (root/name).read_bytes())
  for n in names:copy('TensorRewrite/Pilot/'+n+'.lean')
  if mode=='integration':
   for n in extra:copy('TensorRewrite/Pilot/'+n+'.lean',False)
  for name in rest:copy(name)
  order=['Tensor','ConstantGuard']+(['SliceShape','SliceIndexBounds','IndexMaps'] if mode=='baseline' else ['SliceShapeCore','SliceShapeTransforms','SliceShape','SliceIndexBoundsCore','SliceIndexBounds','IndexMapsCore','IndexMaps'])
  for source in ['TensorRewrite/Pilot/'+n+'.lean' for n in order]+rest:
   out=str(pathlib.Path(source).with_suffix('.olean'));start_one=time.monotonic();p=subprocess.run([lean,source,'-o',out],cwd=w,env=env,text=True,capture_output=True,timeout=30);o=p.stdout+p.stderr
   rows.append({'mode':mode,'source':source,'exit':p.returncode,'seconds':time.monotonic()-start_one,'output':o});assert p.returncode==0 and 'sorryAx' not in o and 'warning:' not in o,(source,o)
   if source==rest[-1]:result[mode]=o
 assert result['baseline']==result['integration'],'Select axiom reports differ'
print(json.dumps({'result':'passed','seconds':time.monotonic()-start,'lean':v,'select_axiom_reports_match':True,'records':rows},indent=2))
