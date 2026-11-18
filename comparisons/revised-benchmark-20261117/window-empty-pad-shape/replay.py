"""Compile only this shape packet with the standalone pinned Lean executable."""
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
    for path in [packet.parent / 'window-early-branches/EarlySpec.lean',
                 packet / 'EmptyFoldSpec.lean', packet / 'EmptyFoldProof.lean',
                 packet / 'EmptyFoldControls.lean']:
        shutil.copy(path, folder)
        start = monotonic()
        result = subprocess.run([lean, '-o', path.stem+'.olean', path.name], cwd=folder,
                                env={**os.environ, 'LEAN_PATH': folder})
        print(path.stem, round(monotonic()-start, 3), result.returncode, flush=True)
        result.check_returncode()
