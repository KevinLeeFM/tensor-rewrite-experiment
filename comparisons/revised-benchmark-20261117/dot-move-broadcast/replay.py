"""Compile local inputs in a new empty directory, using only the pinned Lean installation."""
import os
import pathlib
import shutil
import subprocess
import sys
import tempfile
import time

packet = pathlib.Path(__file__).resolve().parent
root = packet.parents[2]
lean = os.environ.get("LEAN", "lean")
subprocess.run(["sha256sum", "-c", str(packet / "SHA256SUMS")], cwd=root, check=True)
subprocess.run([lean, "--version"], check=True)
names = ["BroadcastDotSpec"]
if "--spec" not in sys.argv:
    names += ["BroadcastDotProof", "BroadcastDotControls"]
with tempfile.TemporaryDirectory() as build:
    tmp = pathlib.Path(build)
    for name in names:
        path = pathlib.Path(name + ".lean")
        (tmp / path).parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile((root if "/" in name else packet) / path, tmp / path)
        start = time.monotonic()
        p = subprocess.run([lean, "-o", name + ".olean", str(path)], cwd=tmp,
                           env={**os.environ, "LEAN_PATH": str(tmp)})
        print(f"{name} {time.monotonic() - start:.3f}s exit={p.returncode}", flush=True)
        p.check_returncode()
