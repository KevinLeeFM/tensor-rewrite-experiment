#!/usr/bin/env python3
"""Replay frozen unsigned remainder statement and controls offline."""
import datetime, hashlib, json, os, pathlib, subprocess, tempfile, time
root = pathlib.Path(__file__).resolve().parents[2]; base = 'comparisons/heldout-remainder-cast/'
manifest = json.loads((root / base / 'freeze.json').read_text())
for name, digest in manifest['files'].items():
    assert hashlib.sha256((root / name).read_bytes()).hexdigest() == digest, name
lean = os.environ.get('LEAN', 'lean')
version = subprocess.run([lean, '--version'], capture_output=True, text=True, check=True).stdout.strip()
assert 'version 4.35.0,' in version and 'eb6cafb7290e8bd5f2937522d8d804f58f02bafc' in version
files = [('TensorRewrite/Pilot/Tensor.lean','TensorRewrite/Pilot/Tensor.olean'),
         (base+'Spec.lean','Spec.olean'), (base+'SpecTests.lean','SpecTests.olean')]
records=[]; start=time.monotonic()
with tempfile.TemporaryDirectory(prefix='remainder-cast-spec-') as tmp:
    env=os.environ.copy(); env['LEAN_PATH']=tmp
    for source,destination in files:
        target=pathlib.Path(tmp)/destination;target.parent.mkdir(parents=True,exist_ok=True);t=time.monotonic()
        r=subprocess.run([lean,source,'-o',str(target)],cwd=root,env=env,capture_output=True,text=True,timeout=30)
        output=r.stdout+r.stderr;records.append({'source':source,'seconds':time.monotonic()-t,'exit_code':r.returncode,'output':output})
        assert r.returncode==0 and 'warning:' not in output and 'sorryAx' not in output,output
    assert 'Heldout.RemainderCast.Goal' in records[1]['output']
    assert 'depends on axioms: [propext]' in records[1]['output']
print(json.dumps({'utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'version':version,
                  'seconds':time.monotonic()-start,'records':records,'result':'passed'},indent=2))
