"""Fresh, targeted replay. Run from any directory with the pinned Lean binary."""
import argparse
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

PACKET = Path(__file__).resolve().parent
ROOT = PACKET.parents[2]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("--lean", default="/workspace/toolchains/lean-4.35.0-linux/bin/lean")
parser.add_argument("--check", nargs="+", default=["NegativeProof", "NegativeControls"])
args = parser.parse_args()
with tempfile.TemporaryDirectory(prefix="pad-negative-") as tmp:
    dest = Path(tmp)
    subprocess.run([sys.executable, PACKET.parent / "signed-pad/extract.py", dest], check=True)
    done = set()
    def compile_module(name):
        if name in done or name == "Std":
            return
        rel = Path(name.replace(".", "/") + ".lean")
        path = dest / rel
        if not path.exists():
            src = PACKET / rel if (PACKET / rel).exists() else ROOT / rel
            path.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(src, path)
            if name == "HistoricalShift":
                original = path.read_text()
                assert original.count("simp only [one_mul]") == 1
                path.write_text(original.replace("simp only [one_mul]", "simp only [Int.one_mul]"))
        for dep in re.findall(r"^(?:public )?import ([\w.]+)", path.read_text(), re.M):
            compile_module(dep)
        start = time.monotonic()
        run = subprocess.run([args.lean, "-o", rel.with_suffix(".olean"), rel], cwd=dest,
                             env={**os.environ, "LEAN_PATH": str(dest)}, capture_output=True, text=True)
        print(f"{name} {time.monotonic()-start:.3f}s rc={run.returncode}", flush=True)
        print(run.stdout + run.stderr, end="")
        if run.returncode or "warning:" in run.stdout + run.stderr:
            raise SystemExit(run.returncode or 1)
        done.add(name)
    for target in args.check:
        compile_module(target)
