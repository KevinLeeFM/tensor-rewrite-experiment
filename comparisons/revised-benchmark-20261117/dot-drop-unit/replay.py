"""Replay the packet in a fresh directory without project oleans."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

here = Path(__file__).resolve().parent
subprocess.run(["sha256sum", "-c", str(here / "SHA256SUMS")], cwd=here.parents[2], check=True)
with tempfile.TemporaryDirectory() as folder:
    for name in ["DropSpec", "DropProof", "DropControls"]:
        shutil.copy(here / (name + ".lean"), folder)
        t = time.monotonic()
        p = subprocess.run([os.getenv("LEAN", "lean"), "-o", name + ".olean", name + ".lean"],
                           cwd=folder, env={**os.environ, "LEAN_PATH": folder})
        print(f"{name} {time.monotonic()-t:.3f}s exit={p.returncode}", flush=True)
        p.check_returncode()
