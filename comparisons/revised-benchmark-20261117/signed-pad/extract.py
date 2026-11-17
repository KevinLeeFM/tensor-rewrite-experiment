"""Materialize only the pinned project sources needed for the two Pad goals."""

import argparse
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[3]
BASE = "672928dbb90a7607c24a7d0281a7db117036608c"
TENSOR = "TensorRewrite/Pilot/Tensor.lean"
LATTICE = "TensorRewrite/Theory/LatticeIndex.lean"
PAD = "comparisons/tensorright-v1/SignedPad.lean"


def source(path):
    """Read the immutable Git blob independently of the working tree."""
    return subprocess.check_output(["git", "show", f"{BASE}:{path}"], cwd=ROOT)


def materialize(destination):
    """Keep definitions byte-for-byte and port a few proof-only simp names."""
    destination = destination.resolve()
    lattice = source(LATTICE).splitlines(keepends=True)
    pad = source(PAD).splitlines(keepends=True)
    files = {
        TENSOR: source(TENSOR),
        "SignedPadLattice.lean": (
            b"module\n\npublic import TensorRewrite.Pilot.Tensor\n"
            + b"".join(lattice[3:50] + lattice[57:91]).replace(
                b"valid.2.1, add_zero", b"valid.2.1, Int.add_zero"
            )
            + b"\nend TensorRewrite.Theory.LatticeIndex\n"
        ),
        "SignedPadHistorical.lean": (
            b"module\n\npublic import SignedPadLattice\n"
            + b"".join(pad[5:97]).replace(
                b"[Nat.cast_add, Nat.cast_one]", b"[Int.natCast_add, Int.natCast_one]"
            ).replace(
                b"[zero, Nat.cast_zero, zero_mul, add_zero]",
                b"[zero, Int.natCast_zero, Int.zero_mul, Int.add_zero]",
            )
            + b"\nend TensorRewrite.PaperComparison.SignedPad\n"
        ),
    }
    for path, contents in files.items():
        target = destination / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(contents)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("destination", type=Path)
    materialize(parser.parse_args().destination)
