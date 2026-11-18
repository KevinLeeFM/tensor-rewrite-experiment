"""Replay in an empty directory with a pinned direct Lean executable."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

packet = Path(__file__).resolve().parent
root = packet.parents[2]
lean = os.environ["LEAN"]
version = subprocess.check_output([lean, "--version"], text=True).strip()
print(version, flush=True)
assert "version 4.35.0" in version
subprocess.run(["sha256sum", "-c", packet / "SHA256SUMS"], cwd=root, check=True)
with tempfile.TemporaryDirectory() as tmp:
    for source in [packet.parent / "reshape-iota-radix/RadixSpec.lean",
                   packet / "ConcatRoundSpec.lean", packet / "ConcatRoundProof.lean",
                   packet / "ConcatRoundControls.lean"]:
        shutil.copyfile(source, Path(tmp) / source.name)
        start = time.monotonic()
        res = subprocess.run([lean, "-o", source.stem + ".olean", source.name],
                             cwd=tmp, env={**os.environ, "LEAN_PATH": tmp})
        print(source.name, f"{time.monotonic()-start:.3f}s", res.returncode, flush=True)
        res.check_returncode()
