import UnitOrderProof
open RevisedBenchmark.UnitOrder
private def sz : Nat → Nat | 0 => 2 | 1 => 1 | _ => 3
private def val (i : Nat) := if i = 0 then 1 else 0
example : visible sz [1,0,2] = [0,2] ∧ ordinal sz val [1,0,2] = 3 := by decide
example : ordinal sz val [0,1,2] ≠ ordinal sz val [2,1,0] := by decide
example : visible sz [2,1,0] = [2,0] := by decide
example : ordinal (fun _ => 1) (fun _ => 0) [2,0,1] = 0 := by decide
example (d : Nat → Nat) : ¬ (∀ i ∈ [0,1], d i < (if i = 1 then 0 else 1)) := by
  intro b
  simpa using b 1 (by decide)
#check (verified : Goal)
