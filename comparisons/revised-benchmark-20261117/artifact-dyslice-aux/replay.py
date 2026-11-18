from pathlib import Path
from tempfile import TemporaryDirectory
from time import monotonic
import os
import shutil
import subprocess

packet = Path(__file__).resolve().parent
subprocess.run(['sha256sum', '-c', packet / 'SHA256SUMS'], cwd=packet.parents[2], check=True)
lean = os.environ['LEAN']
with TemporaryDirectory() as folder:
    for name in ('AuxSpec', 'AuxProof', 'AuxControls'):
        shutil.copyfile(packet / (name + '.lean'), Path(folder) / (name + '.lean'))
        start = monotonic()
        proc = subprocess.run([lean, '-o', name+'.olean', name+'.lean'], cwd=folder,
                              env={**os.environ, 'LEAN_PATH': folder})
        print(name, round(monotonic()-start, 3), proc.returncode, flush=True)
        proc.check_returncode()
