"""Check frozen inputs and compile a fresh, finite Std-only source closure."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

packet = Path(__file__).resolve().parent
root = packet.parents[2]
lean = os.environ.get("LEAN", "lean")
subprocess.run([lean, "--version"], check=True)
subprocess.run(["sha256sum", "-c", packet / "SHA256SUMS"], cwd=root, check=True)
sources = [(root, "TensorRewrite/Pilot/" + n) for n in ("Tensor", "Indexing", "Permutation")]
sources += [(packet.parent / "dot-transpose", n) for n in ("SwapSpec", "SwapProof")]
sources += [(packet, n) for n in ("RemoveSpec", "RemoveProof", "RemoveControls")]
with tempfile.TemporaryDirectory() as tmp:
    for src, name in sources:
        file = Path(tmp) / (name + ".lean")
        file.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(src / (name + ".lean"), file)
        start = time.monotonic()
        run = subprocess.run([lean, "-o", name + ".olean", name + ".lean"], cwd=tmp,
                             env={**os.environ, "LEAN_PATH": tmp}, capture_output=True, text=True)
        print(f"{name} {time.monotonic()-start:.3f}s rc={run.returncode}", flush=True)
        print(run.stdout + run.stderr, end="", flush=True)
        run.check_returncode()
        if "warning:" in run.stdout + run.stderr:
            raise RuntimeError("unexpected Lean warning")
