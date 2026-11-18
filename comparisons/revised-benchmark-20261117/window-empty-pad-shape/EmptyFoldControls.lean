import EmptyFoldProof
set_option autoImplicit false
namespace RevisedBenchmark.EmptyFold
#check (refuted : ¬ Goal)
example : ((geometry 0 1).map (fun d => (originalAxis d).base)) = [2,3] ∧
  ((geometry 0 1).map (fun d => (emittedAxis d).base)) = [0,3] := by decide
example : ((geometry 0 1).map (fun d => (originalAxis d).widthM1+1)) = [2,2] ∧
  (declared (geometry 0 1)).prod = 4 := by decide
example : declared (geometry 1 1) = [4,2] ∧ inferred (geometry 1 1) = [4,2] := by decide
example : declared (geometry 0 0) = [1,2] ∧ inferred (geometry 0 0) = [1,2] := by decide
end RevisedBenchmark.EmptyFold
