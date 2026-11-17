"""Fresh, targeted replay of the reviewed tuple-reduction Git inputs."""
import hashlib
import os
from pathlib import Path
import re
import subprocess
import tempfile
from time import monotonic

ROOT = Path(__file__).resolve().parents[3]
PACKET = Path(__file__).resolve().parent.relative_to(ROOT)
FREEZE = "5f2603ab043d9059300db4d3098da6f0b5ea4cbc"
PROOF = "abb52dad5b5c50a5e20dee0c5f00a2b22162fad6"
PIN = "eb6cafb7290e8bd5f2937522d8d804f58f02bafc"
LEAN = Path(os.environ["LEAN"]).resolve()
AXIOMS = {"propext", "Classical.choice", "Quot.sound"}
CHECKS = """import TupleReduceProof

set_option autoImplicit false
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
open RevisedBenchmark.TupleReduce

example : ∀ {k : Nat} {A : Fin (k+1) → Type} (p : Plan)
    (op : ((c : Fin (k+1)) → A c) → ((c : Fin (k+1)) → A c) →
          ((c : Fin (k+1)) → A c))
    (z : (c : Fin (k+1)) → A c) (xs : (c : Fin (k+1)) → Tensor p.inputShape (A c)),
    (elementCount p.inputShape = 0 ∨ elementCount p.outputShape = 0) →
    (fun c j => reduceTensor p op z (fun i a => xs a i) j c) =
      (fun c => Tensor.constant (z c)) :=
  empty

example : ∀ {k : Nat} {A : Fin (k+1) → Type} (p : Plan)
    (op : ((c : Fin (k+1)) → A c) → ((c : Fin (k+1)) → A c) →
          ((c : Fin (k+1)) → A c))
    (z : (c : Fin (k+1)) → A c)
    (h : elementCount p.inputShape = elementCount p.outputShape),
    (∀ xs : (c : Fin (k+1)) → Tensor p.inputShape (A c),
      (fun c j => reduceTensor p op z (fun i a => xs a i) j c) =
        (fun c => Reshape.reshapeTensor (xs c) p.outputShape h)) ↔
    (elementCount p.outputShape = 0 ∨ ∀ x, op z x = x) :=
  sameCount

private def C (c : Fin 2) : Type := if c.val = 0 then Nat else Bool
private def mk (n : Nat) (b : Bool) (c : Fin 2) : C c :=
  if h : c.val = 0 then by simp [C, h]; exact n
  else by simp [C, h]; exact b
private def reducer (a b : (c : Fin 2) → C c) (c : Fin 2) : C c :=
  if h : c.val = 0 then by
    simp [C, h]
    let n : Nat := b 0
    let m : Nat := a 0
    let left : Bool := a 1
    let right : Bool := b 1
    exact m + n + (if left && right then 1 else 0)
  else by
    simp [C, h]
    let left : Bool := a 1
    let right : Bool := b 1
    exact left != right

private abbrev p : Plan := .keep 2 (.reduce 1 .scalar)
private abbrev j : Index p.outputShape := delinearize p.outputShape ⟨1, by decide⟩
private def input (flag : Bool) (c : Fin 2) (i : Index p.inputShape) : C c :=
  mk (7 + (linearize p.inputShape i).val) flag c

example : original p reducer (mk 0 false) (input true) 0 j = (8 : Nat) := rfl
example : original p reducer (mk 0 false) (input true) 1 j = true := rfl
example : Reshape.reshapeTensor (input true 0) p.outputShape rfl j = (8 : Nat) := rfl
example : Reshape.reshapeTensor (input true 1) p.outputShape rfl j = true := rfl
example : original p reducer (mk 0 true) (input false) 0 j = (8 : Nat) := rfl
example : original p reducer (mk 0 true) (input true) 0 j = (9 : Nat) := rfl
example : original p reducer (mk 0 true) (input true) 0 j ≠
    Reshape.reshapeTensor (input true 0) p.outputShape rfl j := by
  change (9 : Nat) ≠ 8
  decide

private abbrev pe : Plan := .keep 2 (.reduce 0 .scalar)
private abbrev je : Index pe.outputShape := delinearize pe.outputShape ⟨1, by decide⟩
private def emptyInput (c : Fin 2) : Tensor pe.inputShape (C c) := fun _ => mk 88 false c
example : original pe reducer (mk 11 true) emptyInput 0 je = (11 : Nat) := rfl
example : original pe reducer (mk 11 true) emptyInput 1 je = true := rfl
example : original pe reducer (mk 11 true) emptyInput 0 je ≠ (88 : Nat) := by
  change (11 : Nat) ≠ 88
  decide

private abbrev pz : Plan := .keep 0 (.reduce 3 .scalar)
example (i : Index pz.outputShape) : False := by
  have h : elementCount pz.outputShape = 0 := rfl
  exact Fin.elim0 (h ▸ linearize pz.outputShape i)
example (xs : (c : Fin 2) → Tensor pz.inputShape (C c)) :
    original pz reducer (mk 0 true) xs =
      (fun c => Reshape.reshapeTensor (xs c) pz.outputShape rfl) :=
  (sameCount pz reducer (mk 0 true) rfl).2 (.inl rfl) xs

#print axioms RevisedBenchmark.TupleReduce.empty
#print axioms RevisedBenchmark.TupleReduce.sameCount
"""
FALSE_CHECK = """
example : original p reducer (mk 0 true) (input true) 0 j = (8 : Nat) := rfl
"""


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def blob(commit, path):
    return subprocess.check_output(["git", "show", f"{commit}:{path}"], cwd=ROOT)


def replay(temp):
    start = monotonic()
    manifest = PACKET / "SHA256SUMS"
    frozen = blob(FREEZE, manifest)
    require(frozen == blob(PROOF, manifest), "Changed freeze")
    require(blob(PROOF, "lean-toolchain").strip() == b"leanprover/lean4:v4.35.0",
            "Changed toolchain pin")
    sources = {}
    hashes = frozen.decode().splitlines()
    for line in hashes:
        digest, path = line.split(maxsplit=1)
        data = blob(PROOF, path)
        require(hashlib.sha256(data).hexdigest() == digest and blob(FREEZE, path) == data,
                f"Changed frozen input: {path}")
        if path.endswith(".lean"):
            name = path.removesuffix(".lean").replace("/", ".") if path.startswith(
                "TensorRewrite/") else Path(path).stem
            sources[name] = data
    proof = PACKET / "TupleReduceProof.lean"
    sources["TupleReduceProof"] = blob(PROOF, proof)
    print(f"Verified {len(hashes)} hashes in freeze/proof Git objects: {monotonic()-start:.3f}s",
          flush=True)

    env = dict(os.environ, LEAN_PATH=str(temp), LEAN_SRC_PATH="")
    total = 0.0

    def run(file, *, emit=False, negative=False):
        nonlocal total
        start = monotonic()
        args = ["-o", str(file.with_suffix(".olean"))] if emit else []
        result = subprocess.run([str(LEAN), *args, str(file)], capture_output=True,
                                text=True, timeout=20, cwd=temp, env=env)
        duration = monotonic() - start
        total += duration
        print(f"{file.relative_to(temp)} rc={result.returncode} {duration:.3f}s", flush=True)
        print(result.stdout + result.stderr, end="", flush=True)
        if negative:
            require(result.returncode != 0 and result.stdout.count("error:") == 1 and
                    "Type mismatch" in result.stdout and not result.stderr,
                    "False output observation did not fail as expected")
        else:
            require(result.returncode == 0 and not result.stderr and
                    "warning:" not in result.stdout, "Unexpected Lean diagnostic")
        return result.stdout

    compiled = set()
    visiting = set()

    def compile_module(name):
        if name in compiled or name == "Std":
            return
        require(name in sources and name not in visiting, f"Unexpected import: {name}")
        visiting.add(name)
        source = sources[name]
        require(not re.search(rb"\b(?:sorry|admit|sorryAx|native_decide|axiom|unsafe|run_cmd)\b",
                              source), f"Prohibited syntax: {name}")
        for imports in re.findall(rb"^(?:public )?import ([\w. ]+)$", source, re.M):
            for dependency in imports.decode().split():
                compile_module(dependency)
        file = temp / (name.replace(".", "/") + ".lean")
        file.parent.mkdir(parents=True, exist_ok=True)
        file.write_bytes(source)
        run(file, emit=True)
        compiled.add(name)
        visiting.remove(name)

    compile_module("TupleReduceProof")
    require(compiled == set(sources), "Declared imports differ from replayed closure")
    independent = temp / "Checks.lean"
    independent.write_text(CHECKS)
    report = run(independent)
    audits = re.findall(r"'RevisedBenchmark\.TupleReduce\.(\w+)' depends on axioms: \[(.*?)\]",
                        report)
    require(dict((name, set(axioms.split(", "))) for name, axioms in audits) ==
            {"empty": AXIOMS, "sameCount": AXIOMS}, "Unexpected axiom closure")
    negative = temp / "RejectWrongValue.lean"
    negative.write_text(CHECKS + FALSE_CHECK)
    run(negative, negative=True)
    print(f"Total compiler time including expected rejection: {total:.3f}s")


if __name__ == "__main__":
    version = subprocess.check_output([str(LEAN), "--version"], text=True, timeout=5)
    require("version 4.35.0" in version and PIN in version, f"Wrong Lean: {version!r}")
    print(version, end="", flush=True)
    with tempfile.TemporaryDirectory(prefix="tuple-reduce-independent-") as directory:
        replay(Path(directory))
