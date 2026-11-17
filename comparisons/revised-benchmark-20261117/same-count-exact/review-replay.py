"""Replay the reviewed same-count proof against the exact Git inputs.

Run from any directory with Python 3 and LEAN set to the pinned Lean executable.
"""
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
from time import monotonic

ROOT = Path(__file__).resolve().parents[3]
PACKET = Path(__file__).resolve().parent.relative_to(ROOT)
FREEZE_COMMIT = "1e7c5dedc94f53de9305b5debc50fa9637247f5a"
PROOF_COMMIT = "55fce93585480380834491c33bb0d827717b8814"
LEAN = Path(os.environ["LEAN"]).resolve()
VERSION = "commit eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
CHECKS = """import SameCountProof

set_option autoImplicit false
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
open RevisedBenchmark.SameCountExact

example : ∀ {α : Type} (p : Plan) (op : α → α → α) (z : α)
    (h : elementCount p.inputShape = elementCount p.outputShape)
    (a : Tensor p.inputShape α),
    (reduceTensor p op z a = Reshape.reshapeTensor a p.outputShape h) ↔
      ∀ i : Index p.outputShape, op z (Reshape.reshapeTensor a p.outputShape h i) =
        Reshape.reshapeTensor a p.outputShape h i :=
  pointwise_iff

example : ∀ {α : Type} (p : Plan) (op : α → α → α) (z : α)
    (h : elementCount p.inputShape = elementCount p.outputShape),
    (∀ a : Tensor p.inputShape α, reduceTensor p op z a =
      Reshape.reshapeTensor a p.outputShape h) ↔
    (elementCount p.outputShape = 0 ∨ ∀ x : α, op z x = x) :=
  uniform_iff

private abbrev p : Plan := .keep 2 (.reduce 1 (.keep 3 .scalar))
private abbrev i : Index p.outputShape := delinearize p.outputShape ⟨5, by decide⟩
private def a : Tensor p.inputShape Nat := fun j => (linearize p.inputShape j).val

example : reduceTensor p Nat.add 1 a i = 6 := rfl
example : Reshape.reshapeTensor a p.outputShape rfl i = 5 := rfl
example : reduceTensor p Nat.add 1 a ≠ Reshape.reshapeTensor a p.outputShape rfl := by
  intro h
  have wrong : (6 : Nat) = 5 := congrFun h i
  contradiction

#print axioms RevisedBenchmark.SameCountExact.pointwise_iff
#print axioms RevisedBenchmark.SameCountExact.uniform_iff
"""


def git_blob(commit, path):
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def check_file_hashes(temp):
    files = git_blob(FREEZE_COMMIT, PACKET / "freeze.json")
    require(git_blob(PROOF_COMMIT, PACKET / "freeze.json") == files, "Changed freeze")
    freeze = json.loads(files)
    require(set(freeze["allowed_axioms"]) == AXIOMS, "Changed axiom policy")
    require(git_blob(PROOF_COMMIT, "lean-toolchain").strip() == b"leanprover/lean4:v4.35.0",
            "Wrong toolchain pin")
    for name, digest in freeze["files"].items():
        data = git_blob(PROOF_COMMIT, name)
        require(hashlib.sha256(data).hexdigest() == digest, f"Wrong hash: {name}")
        reference = FREEZE_COMMIT if name.startswith(str(PACKET)) else freeze["baseline"]
        require(git_blob(reference, name) == data, f"Changed original frozen input: {name}")
    paths = {name.removesuffix(".lean").replace("/", "."): name for name in freeze["files"]
             if name.startswith("TensorRewrite/")}
    for module in ("SameCountSpec", "SameCountProof", "SameCountControls"):
        paths[module] = str(PACKET / f"{module}.lean")
    sources = {}
    for module, path in paths.items():
        data = git_blob(PROOF_COMMIT, path)
        require(not re.search(rb"\b(?:sorry|admit|sorryAx|native_decide|axiom|unsafe|run_cmd)\b", data),
                f"Prohibited syntax: {path}")
        source = temp / (module.replace(".", "/") + ".lean")
        source.parent.mkdir(parents=True, exist_ok=True)
        source.write_bytes(data)
        sources[module] = source
    print(f"Verified {len(freeze['files'])} hashes and earlier committed files", flush=True)
    return sources


def run_lean(temp, sources):
    env = os.environ.copy()
    env["LEAN_PATH"] = str(temp)
    total = 0.0

    def run(source, emit=False, expected_failure=None):
        nonlocal total
        command = [str(LEAN)]
        if emit:
            command += ["-o", str(source.with_suffix(".olean"))]
        start = monotonic()
        proc = subprocess.run(command + [str(source)], capture_output=True, text=True,
                              cwd=temp, env=env, timeout=20)
        seconds = monotonic() - start
        total += seconds
        print(f"{source.relative_to(temp)} rc={proc.returncode} {seconds:.3f}s", flush=True)
        print(proc.stdout + proc.stderr, end="", flush=True)
        if expected_failure:
            require(proc.returncode != 0 and expected_failure in proc.stdout + proc.stderr,
                    "Negative harness failed to reject the false claim as expected")
        else:
            require(proc.returncode == 0 and not proc.stderr and "warning:" not in proc.stdout,
                    "Unexpected diagnostic")
        return proc.stdout

    compiled = set()

    def compile_module(name):
        if name in compiled or name == "Std":
            return
        require(name in sources, f"Unfrozen import: {name}")
        source = sources[name]
        for imports in re.findall(r"^(?:public )?import (.+)$", source.read_text(), re.M):
            for dependency in imports.split():
                compile_module(dependency)
        run(source, emit=True)
        compiled.add(name)

    compile_module("SameCountControls")
    require(compiled == set(sources), "Frozen imports differ from replayed closure")
    check = temp / "IndependentChecks.lean"
    check.write_text(CHECKS)
    output = run(check)
    audits = re.findall(r"'RevisedBenchmark\.SameCountExact\.(\w+)' depends on axioms: \[(.*?)\]",
                        output)
    require(dict((name, set(axioms.split(", "))) for name, axioms in audits) ==
            {"pointwise_iff": AXIOMS, "uniform_iff": AXIOMS}, "Unexpected axiom closure")
    negative = temp / "RejectWrongValue.lean"
    negative.write_text(CHECKS.split("example : reduceTensor p Nat.add 1 a i = 6")[0] +
                        "example : reduceTensor p Nat.add 1 a i = 5 := rfl\n")
    run(negative, expected_failure="Type mismatch")
    print(f"Compiler time, including expected negative diagnostic: {total:.3f}s")


def main():
    version = subprocess.check_output([str(LEAN), "--version"], text=True, timeout=5)
    require(VERSION in version, f"Wrong Lean: {version!r}")
    print(version, end="", flush=True)
    with tempfile.TemporaryDirectory(prefix="same-count-independent-") as directory:
        temp = Path(directory)
        run_lean(temp, check_file_hashes(temp))


if __name__ == "__main__":
    main()
