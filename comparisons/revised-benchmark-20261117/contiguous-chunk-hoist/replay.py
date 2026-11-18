"""Replay in a fresh private directory with a direct pinned Lean binary."""
from pathlib import Path
from tempfile import TemporaryDirectory
from time import monotonic
import os
import shutil
import subprocess
import sys

packet = Path(__file__).resolve().parent
subprocess.run(['sha256sum','-c',packet/'SHA256SUMS'],cwd=packet.parents[2],check=True)
names = ['ChunkSpec','ChunkProof']
if '--proof-only' not in sys.argv:
    names.append('ChunkControls')
with TemporaryDirectory() as tmp:
    for name in names:
        shutil.copyfile(packet/(name+'.lean'), Path(tmp)/(name+'.lean'))
        start = monotonic()
        proc = subprocess.run([os.environ['LEAN'],'-o',name+'.olean',name+'.lean'],
                              cwd=tmp, env={**os.environ,'LEAN_PATH':tmp})
        print(name, round(monotonic()-start,3), proc.returncode, flush=True)
        proc.check_returncode()
