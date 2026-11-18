"""Replay only the frozen U8 empty-gather packet."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
packet = Path(__file__).resolve().parent
subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=packet, check=True)
with tempfile.TemporaryDirectory() as folder:
    for name in ("GatherEmptySpec", "GatherEmptyProof", "GatherEmptyControls"):
        src = packet / (name + ".lean")
        shutil.copyfile(src, Path(folder) / src.name)
        start = time.monotonic()
        run = subprocess.run([os.environ.get("LEAN", "lean"), "-o", name + ".olean", src.name],
                             cwd=folder, env={**os.environ, "LEAN_PATH":folder})
        print(f"{name} {time.monotonic()-start:.3f}s exit={run.returncode}", flush=True)
        run.check_returncode()
