#!/usr/bin/env python3
"""Fresh, offline replay of the isolated WorkerSuffix theorem."""
import os
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
base = "comparisons/heldout-space-depth-selection/"
lean = "/workspace/toolchains/lean-4.35.0-linux/bin/lean"
files = [
    ("TensorRewrite/Pilot/" + n + ".lean", "TensorRewrite/Pilot/" + n + ".olean")
    for n in ["Tensor", "Indexing", "Permutation", "FiniteProduct", "LinearIndex",
              "ConstantGuard", "Reshape", "FiniteProductLemmas", "LinearIndexLemmas"]
]
files += [("TensorRewrite/Theory/" + n + ".lean", "TensorRewrite/Theory/" + n + ".olean")
          for n in ["Concatenation", "ConcatenationLemmas"]]
files += [(base + n + ".lean", n + ".olean") for n in [
    "ShapeBridge", "SliceTransport", "OrderedSlices", "ChunkIntervals", "SourceFrame",
    "ElementCount", "GoalCandidate", "CoordinateBridge", "CoordinateChunkAdapter",
    "IndexTransportAttempt", "ProductAssociation", "ContextAssociation",
    "PermutationCoordinate", "PermutationRegions", "RecursiveShapeSplit", "PlanShapeSplit",
    "OriginalSplitConnection", "TailHeadConnection", "WorkerSuffix"]]

with tempfile.TemporaryDirectory(prefix="worker-suffix-") as tmp:
    env = os.environ.copy()
    env["LEAN_PATH"] = tmp
    for src, dest in files:
        out = Path(tmp) / dest
        out.parent.mkdir(parents=True, exist_ok=True)
        result = subprocess.run([lean, src, "-o", str(out)], cwd=root, env=env,
                                capture_output=True, text=True, check=False, timeout=60)
        if result.returncode:
            raise SystemExit(f"FAIL {src}\n{result.stdout}{result.stderr}")
        if dest == "WorkerSuffix.olean":
            output = result.stdout + result.stderr
            if "warning:" in output or "sorryAx" in output:
                raise SystemExit(output)
            print(output, end="")
            print("PASS: fresh offline WorkerSuffix replay")
