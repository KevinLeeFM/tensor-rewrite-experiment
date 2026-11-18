import CopySpec
namespace RevisedBenchmark.CopyReshape
open CopyChain
/-- I = Fin n numbers the common logical row-major positions across the reshape. -/
abbrev Dense (n : Nat) := Layout (Fin n) n

def previous {n : Nat} (before : Bool) (base prior : Dense n) (mem : Fin n → α) :=
  if before then copy base prior mem else mem

def old {n : Nat} (before : Bool) (base prior shaped final : Dense n) (mem : Fin n → α) :=
  let operand := if before then prior else base
  copy shaped final (copy operand shaped (previous before base prior mem))

def replacement {n : Nat} (before omit raw : Bool) (base prior aligned final : Dense n)
    (mem : Fin n → α) :=
  let operand := if before then prior else base
  let chosen := if omit then mem else copy operand aligned (previous before base prior mem)
  if raw then chosen else copy aligned final chosen

def Goal := ∀ (n : Nat) (α : Type) (before omit raw : Bool)
  (base prior shaped aligned final : Dense n) (mem : Fin n → α),
  (omit = true → before = true ∧ aligned = base) →
  (raw = true → ∀ row, aligned.address row = final.address row) →
  old before base prior shaped final mem = replacement before omit raw base prior aligned final mem
end RevisedBenchmark.CopyReshape
