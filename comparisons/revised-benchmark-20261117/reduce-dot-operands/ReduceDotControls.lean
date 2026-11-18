import ReduceDotProof

set_option autoImplicit false

namespace RevisedBenchmark.ReduceDotOperands

example : oldCost 3 3 = 80 ∧ newCost 3 3 = 24 := by decide
example : original left right = 9 ∧ replacement left right = 0 := by decide
example : ¬ admitted 1 1 := by unfold admitted; decide
example : ¬ admitted 1 2 := by unfold admitted; decide
example : ¬ admitted 0 3 := by unfold admitted; decide

/-- After operand reduction the corrected pairing reads the right operand at (q,p). -/
def corrected {m n : Nat} (a : Operand m) (b : Operand n) : Int :=
  addZero fun p => addZero fun q =>
    (addZero fun i => a i p q) * (addZero fun j => b j q p)

example : corrected left right = original left right := by decide
example : Case := verified

end RevisedBenchmark.ReduceDotOperands
