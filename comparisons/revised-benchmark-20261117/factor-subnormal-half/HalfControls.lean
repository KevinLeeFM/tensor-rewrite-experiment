import HalfProof
namespace RevisedBenchmark.HalfFactor
example : old true false 1 1 = 0 ∧ newValue 1 1 = 1 := by decide
example : old false true 3 3 = 4 ∧ newValue 3 3 = 3 := by decide
example : old false false 3 1 = newValue 3 1 := by decide
example : old true true 2097151 1 = newValue 2097151 1 := by decide
end RevisedBenchmark.HalfFactor
