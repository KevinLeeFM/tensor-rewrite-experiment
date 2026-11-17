"""Replay the frozen Pad goals and checked proofs in a fresh Lean 4.35 directory."""

import argparse
from hashlib import sha256
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

from extract import ROOT, materialize

PACKET = Path(__file__).resolve().parent
LEAN_COMMIT = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
MODULES = ("TensorRewrite/Pilot/Tensor", "SignedPadLattice", "SignedPadHistorical", "SignedPadSpec")
ALLOWED_AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
THEOREMS = ("RevisedBenchmark.HandlePad.unit_interior", "RevisedBenchmark.HandlePad.empty_input")


def check_freeze(stage):
    """Check exact project input bytes, including the generated excerpts."""
    roots = {"generated": stage, "packet": PACKET, "repo": ROOT}
    for line in (PACKET / "FREEZE.sha256").read_text().splitlines():
        expected, reference = line.split("  ")
        base, path = reference.split("/", 1)
        actual = sha256((roots[base] / path).read_bytes()).hexdigest()
        if actual != expected:
            raise SystemExit(f"Frozen source mismatch: {reference}")


def compile_module(lean, stage, module):
    started = time.perf_counter()
    result = subprocess.run(
        [lean, "-o", f"{module}.olean", f"{module}.lean"],
        cwd=stage, env={**os.environ, "LEAN_PATH": str(stage)},
        capture_output=True, text=True, timeout=20,
    )
    print(f"{module}: {time.perf_counter() - started:.3f}s, exit {result.returncode}", flush=True)
    print(result.stdout, end="")
    print(result.stderr, end="")
    if result.returncode or result.stderr or "warning:" in result.stdout:
        raise SystemExit(f"Unexpected diagnostics for {module}")
    return result.stdout


def check_axioms(output):
    """Require one actual axiom report per frozen terminal theorem."""
    for name in THEOREMS:
        reports = [line for line in output.splitlines() if line.startswith(f"'{name}' ")]
        if len(reports) != 1:
            raise SystemExit(f"Missing or duplicate axiom report for {name}")
        report = reports[0]
        if report == f"'{name}' does not depend on any axioms":
            continue
        prefix = f"'{name}' depends on axioms: ["
        if not report.startswith(prefix) or not report.endswith("]"):
            raise SystemExit(f"Malformed axiom report: {report}")
        if set(report[len(prefix):-1].split(", ")) - ALLOWED_AXIOMS:
            raise SystemExit(f"Unapproved axioms: {report}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lean", default=os.getenv("LEAN", "lean"))
    parser.add_argument("--spec-only", action="store_true")
    args = parser.parse_args()
    lean = shutil.which(args.lean)
    if lean is None:
        raise SystemExit(f"Lean executable unavailable: {args.lean}")
    version = subprocess.check_output([lean, "--version"], text=True)
    print(version.strip(), flush=True)
    if "version 4.35.0," not in version or f"commit {LEAN_COMMIT}," not in version:
        raise SystemExit("Wrong compiler pin")
    with tempfile.TemporaryDirectory(prefix="handle-pad-") as directory:
        stage = Path(directory)
        materialize(stage)
        check_freeze(stage)
        shutil.copyfile(PACKET / "SignedPadSpec.lean", stage / "SignedPadSpec.lean")
        for module in MODULES:
            compile_module(lean, stage, module)
        if not args.spec_only:
            for module in ("SignedPadProof", "SignedPadControls"):
                shutil.copyfile(PACKET / f"{module}.lean", stage / f"{module}.lean")
            check_axioms(compile_module(lean, stage, "SignedPadProof"))
            compile_module(lean, stage, "SignedPadControls")


if __name__ == "__main__":
    main()
