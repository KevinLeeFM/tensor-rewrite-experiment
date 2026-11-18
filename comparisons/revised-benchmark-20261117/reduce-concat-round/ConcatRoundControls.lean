import ConcatRoundProof
set_option autoImplicit false
namespace RevisedBenchmark.ReduceConcat
example : ¬ StrictCase := refuted
example : original 1 2 3 4 = 10 ∧ replacement 1 2 3 4 = 10 := by decide
example : add32 16777216 1 = 16777216 ∧ add32 16777218 1 = 16777220 := by decide
example : reduce32 [1,1] = 2 ∧ add32 16777216 2 = 16777218 := by decide
example : original 16777216 0 1 1 ≠ replacement 16777216 0 1 1 := by decide
#print axioms refuted
#print axioms witness
end RevisedBenchmark.ReduceConcat
