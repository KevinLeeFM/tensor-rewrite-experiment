"""Replay the frozen custom closure with an empty temporary Lean module directory."""
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time

packet = Path(__file__).resolve().parent
root = packet.parents[2]
lean = os.environ.get("LEAN", "lean")
aliases = {
    "PaperIota": root / "comparisons/tensorright-v1/Iota.lean",
    "OrderedSpec": packet.parent / "broadcast-reshape-ordered/OrderedSpec.lean",
    "OrderedProof": packet.parent / "broadcast-reshape-ordered/OrderedProof.lean",
}
for name in ("ShapeBridge", "ElementCount"):
    aliases[name] = root / f"comparisons/heldout-space-depth-selection/{name}.lean"
aliases["UnitSpec"] = packet.parent / "broadcast-unit-edits/UnitSpec.lean"
for name in ("Spec", "Guard", "Proof"):
    aliases[name] = root / f"comparisons/heldout-unit-reverse-v1/{name}.lean"
for name in ("RemapSpec", "RemapProof", "RemapControls"):
    aliases[name] = packet / f"{name}.lean"

for row in (packet / "SHA256SUMS").read_text().splitlines():
    digest, name = row.split("  ", 1)
    if hashlib.sha256((root / name).read_bytes()).hexdigest() != digest:
        raise SystemExit(f"frozen hash mismatch: {name}")

compiled = set()
with tempfile.TemporaryDirectory(prefix="reverse-remap-") as tmp:
    def compile_module(name):
        if name in compiled:
            return
        src = aliases.get(name, root / (name.replace(".", "/") + ".lean"))
        for dep in re.findall(r"^(?:public )?import (\S+)", src.read_text(), re.M):
            if dep not in ("Std", "Init", "Lean"):
                compile_module(dep)
        dst = Path(tmp) / (name.replace(".", "/") + ".olean")
        dst.parent.mkdir(parents=True, exist_ok=True)
        start = time.monotonic()
        proc = subprocess.run([lean, "-o", str(dst), str(src)], cwd=root,
                              env={**os.environ, "LEAN_PATH": tmp}, text=True, capture_output=True)
        print(name, round(time.monotonic() - start, 3), proc.returncode, proc.stdout, proc.stderr, flush=True)
        proc.check_returncode()
        compiled.add(name)
    compile_module("RemapControls")
