"""Compile the frozen spec, proof and controls with private fresh outputs."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time
here = Path(__file__).resolve().parent
subprocess.run(["sha256sum", "-c", "SHA256SUMS"], cwd=here, check=True)
with tempfile.TemporaryDirectory() as tmp:
    for name in ["FiberSpec", "FiberProof", "FiberControls"]:
        shutil.copyfile(here / (name + ".lean"), Path(tmp) / (name + ".lean"))
        t = time.monotonic()
        cmd = [os.environ.get("LEAN", "lean"), "-o", name + ".olean", name + ".lean"]
        run = subprocess.run(cmd, cwd=tmp, env={**os.environ, "LEAN_PATH":tmp})
        print(f"{name} {time.monotonic()-t:.3f}s return code {run.returncode}", flush=True)
        run.check_returncode()
