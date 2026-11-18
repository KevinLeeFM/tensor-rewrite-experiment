"""Compile this packet with the pinned standalone Lean installation."""
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
    for stem in ('RadixSpec', 'NestedSpec', 'PromotionSpec', 'PrecisionSpec', 'PrecisionProof', 'PrecisionControls'):
        source = packet.parent / 'reshape-iota-radix' if stem == 'RadixSpec' else packet.parent / 'nested-dot-round' if stem == 'NestedSpec' else packet.parent / 'conv-bfloat-promotion' if stem == 'PromotionSpec' else packet
        shutil.copy(source / (stem+'.lean'), folder)
        start = monotonic()
        result = subprocess.run([lean, '-o', stem+'.olean', stem+'.lean'], cwd=folder,
                                env={**os.environ, 'LEAN_PATH': folder})
        print(stem, round(monotonic()-start, 3), result.returncode, flush=True)
        result.check_returncode()
