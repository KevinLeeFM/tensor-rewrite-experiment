"""Replay only the packet modules with a fresh local olean directory."""
import datetime
import os
import pathlib
import subprocess
import tempfile
import time

root = pathlib.Path(__file__).resolve().parent
lean = os.environ.get("LEAN", "/workspace/toolchains/lean-4.35.0-linux/bin/lean")
with tempfile.TemporaryDirectory() as tmp:
    for mod in ("ScalarSpec", "ScalarProof", "ScalarControls"):
        start = time.monotonic()
        print(datetime.datetime.now(datetime.timezone.utc).isoformat(), mod, flush=True)
        cmd = [lean, "-o", f"{tmp}/{mod}.olean", f"{mod}.lean"]
        result = subprocess.run(cmd, cwd=root, env={**os.environ, "LEAN_PATH": tmp})
        print(f"seconds={time.monotonic()-start:.3f} return={result.returncode}", flush=True)
        result.check_returncode()
