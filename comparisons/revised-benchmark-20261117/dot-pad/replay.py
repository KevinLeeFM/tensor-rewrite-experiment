"""Check the frozen inputs and compile the packet into a new temporary directory."""
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
names = ["PadDotSpec"] if "--spec" in sys.argv else ["PadDotSpec", "PadDotProof", "PadDotControls"]
with tempfile.TemporaryDirectory() as dest:
    for name in names:
        shutil.copyfile(packet / (name + ".lean"), pathlib.Path(dest) / (name + ".lean"))
        start = time.monotonic()
        result = subprocess.run([lean, "-o", name + ".olean", name + ".lean"], cwd=dest,
                                env={**os.environ, "LEAN_PATH": dest})
        print(f"{name} {time.monotonic()-start:.3f}s exit={result.returncode}", flush=True)
        result.check_returncode()
