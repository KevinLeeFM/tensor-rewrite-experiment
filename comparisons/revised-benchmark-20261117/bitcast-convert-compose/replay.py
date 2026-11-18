#!/usr/bin/env python3
"""Replay only the packet-local Std-only shape-inference model; no Lake."""
from __future__ import annotations
import os
import pathlib
import subprocess
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[3]
SOURCE = pathlib.Path(__file__).resolve().with_name("ShapeInference.lean")
LEAN = pathlib.Path(os.environ.get(
    "LEAN", "/workspace/toolchains/lean-4.35.0-linux/bin/lean"))

version = subprocess.run([str(LEAN), "--version"], check=True, text=True,
                         capture_output=True)
print(version.stdout.strip())
if "Lean (version 4.35.0," not in version.stdout:
    raise SystemExit("unexpected Lean version")
with tempfile.TemporaryDirectory(prefix="bitcast-shape-replay-") as tmp:
    out = pathlib.Path(tmp) / "ShapeInference.olean"
    result = subprocess.run([str(LEAN), str(SOURCE), "-o", str(out)],
                            cwd=ROOT, text=True, capture_output=True)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode:
        raise SystemExit(result.returncode)
    if not out.is_file():
        raise SystemExit("Lean returned success without producing the target olean")
