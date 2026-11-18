import ScaleProof
set_option autoImplicit false
namespace RevisedBenchmark.ConvSelectScale
example (s : Bool) : (original s 2 2 3 5 true, original s 2 2 3 5 false) = (12,10) := by
  cases s <;> decide
example (s : Bool) : (moved s 2 2 3 5 true, moved s 2 2 3 5 false) = (12,20) := by
  cases s <;> decide
example : original true 2 1 3 5 false = moved true 2 1 3 5 false := by decide
example : original false 2 2 3 0 false = moved false 2 2 3 0 false := by decide
#check (refuted true : ¬Case true)
#check (refuted false : ¬Case false)
end RevisedBenchmark.ConvSelectScale
