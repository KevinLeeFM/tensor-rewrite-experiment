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
names = ['TensorRewrite/Pilot/FiniteProduct', 'TensorRewrite/Pilot/FiniteProductLemmas', 'TensorRewrite/Pilot/Tensor', 'TensorRewrite/Pilot/LinearIndex', 'TensorRewrite/Pilot/Indexing', 'TensorRewrite/Pilot/Permutation', 'TensorRewrite/Pilot/PermutationArrays', 'TensorRewrite/Pilot/DenseLayout', 'TensorRewrite/Pilot/LinearIndexLemmas', 'TensorRewrite/Pilot/PermutationArrayLemmas', 'TensorRewrite/Pilot/DenseLayoutLemmas', 'TensorRewrite/Theory/BitPacking', 'TensorRewrite/Theory/BitPackingLemmas', 'TensorRewrite/Theory/BitPackingProof'] + (["PackSpec"] if "--spec" in sys.argv else ["PackSpec", "PackProof", "PackControls"])
with tempfile.TemporaryDirectory() as dest:
    for name in names:
        target = pathlib.Path(dest) / (name + ".lean")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile((root if "/" in name else packet) / (name + ".lean"), target)
        start = time.monotonic()
        result = subprocess.run([lean, "-o", name + ".olean", name + ".lean"], cwd=dest,
                                env={**os.environ, "LEAN_PATH": dest})
        print(f"{name} {time.monotonic()-start:.3f}s exit={result.returncode}", flush=True)
        result.check_returncode()
