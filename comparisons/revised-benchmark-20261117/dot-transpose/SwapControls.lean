import SwapProof
open TensorRewrite.Pilot RevisedBenchmark.DotSwap
private def cycle : AxisPermutation 3 :=
  ⟨(·+1), (·+2), by decide, by decide⟩
private def reverseSlots : AxisPermutation 3 := ⟨Fin.rev, Fin.rev, Fin.rev_rev, Fin.rev_rev⟩
private def anyQ (a : Fin 3) := a.val
private def x (q : Fin 3 → Nat) (i : Fin 2) (t : Fin 2) : Int :=
  2 + (q 0 : Int) + 3*(q 1 : Int) + 9*(i.val : Int) + t.val
private def y (q : Fin 3 → Nat) (j : Fin 4) (t : Fin 2) : Int :=
  -1 + 3*(q 2 : Int) + 7*(j.val : Int) - t.val
private def lhs := dot 2 reverseSlots (AxisPermutation.identity _) x y (operandBatch cycle anyQ) 1 3
example : lhs = dot 2 ((AxisPermutation.identity _).comp cycle) (reverseSlots.comp cycle)
    y x anyQ 3 1 := by decide
example : lhs ≠ dot 2 ((AxisPermutation.identity _).comp cycle) (cycle.comp reverseSlots)
    y x anyQ 3 1 := by decide
example : lhs ≠ dot 2 (AxisPermutation.identity _) reverseSlots y x anyQ 3 1 := by decide
example : dot (b := 0) 0 (AxisPermutation.identity _) (AxisPermutation.identity _)
    (fun _ (_ : Unit) _ => (17 : Int)) (fun _ (_ : Unit) _ => -4) (fun _ => 0) () () = 0 := by decide
