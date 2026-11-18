import FullFastProof
set_option autoImplicit false
namespace RevisedBenchmark.WindowFullF32
example : window [16777216,1,1] 0 = 16777216 := by decide
example : reshapedFast [16777216,1,1] 0 = 16777218 := by decide
example : window [1,1,16777216] 0 = reshapedFast [1,1,16777216] 0 := by decide
example : window [4,2,1] 0 = 7 ∧ reshapedFast [4,2,1] 0 = 7 := by decide
#check (refuted : ¬ Goal)
end RevisedBenchmark.WindowFullF32
