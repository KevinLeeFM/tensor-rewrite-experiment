import MergeProof
namespace RevisedBenchmark.MergeAxes
def data (i j k : Nat) : Int := i*10+j+k
example : original true 2 3 data 0 2 = 44 ∧ merged 2 3 data 0 2 = 38 := by decide
example : original false 2 3 data 0 2 = 42 := by decide
example : original true 0 3 data 0 2 = 8 ∧ merged 0 3 data 0 2 = 2 := by decide
example : mergedDims true = [0,1] ∧ lifted 0 0 ≠ 0 := by decide
end RevisedBenchmark.MergeAxes
