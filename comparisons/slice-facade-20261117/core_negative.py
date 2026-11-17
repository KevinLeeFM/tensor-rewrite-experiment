#!/usr/bin/env python3
"""Check both transform names are unavailable through the proposed core-only import."""
import json,os,pathlib,shutil,subprocess,tempfile,time
here=pathlib.Path(__file__).resolve().parent; proto=here/'prototype/TensorRewrite/Pilot';lean=os.environ.get('LEAN','lean'); start=time.monotonic(); rows=[]
with tempfile.TemporaryDirectory(prefix='slice-core-negative-') as td:
 w=pathlib.Path(td);d=w/'TensorRewrite/Pilot';d.mkdir(parents=True);env=os.environ.copy();env['LEAN_PATH']=str(w)
 for name in ['SliceShapeCore','SliceIndexBoundsCore']:
  shutil.copyfile(proto/(name+'.lean'),d/(name+'.lean'))
  p=subprocess.run([lean,'TensorRewrite/Pilot/'+name+'.lean','-o','TensorRewrite/Pilot/'+name+'.olean'],cwd=w,env=env,capture_output=True,text=True,timeout=30);assert p.returncode==0,p.stdout+p.stderr
 for name in ['removeRedundantStride','reorderReverse']:
  (w/'Probe.lean').write_text('import TensorRewrite.Pilot.SliceIndexBoundsCore\n#check TensorRewrite.Pilot.SliceShape.'+name+'\n')
  p=subprocess.run([lean,'Probe.lean'],cwd=w,env=env,capture_output=True,text=True,timeout=30);output=p.stdout+p.stderr
  assert p.returncode!=0 and 'Unknown identifier' in output,(name,output)
  rows.append({'declaration':name,'exit':p.returncode,'output':output})
print(json.dumps({'result':'passed','seconds':time.monotonic()-start,'negative_checks':rows},indent=2))
