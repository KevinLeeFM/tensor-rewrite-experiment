import LayoutProof
namespace RevisedBenchmark.ConvDotOrder
example : conv 3 0 1 id 1 = 1 ∧ dot true 2 3 0 1 id 1 = 2 := by decide
example : Case false 2 3 := (criterion ..).mpr (by decide)
example : Case true 4 1 := (criterion ..).mpr (by decide)
example : Case true 0 4 := (criterion ..).mpr (by decide)
end RevisedBenchmark.ConvDotOrder
