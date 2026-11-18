import ClampProof
namespace RevisedBenchmark.ClampGuard
example : old false 2 0 1 = 2 ∧ old true 2 0 1 = 2 ∧ clipped 2 0 1 = 1 := by decide
example : old true 0 2 1 = clipped 0 2 1 := by decide
example : old false 3 (-4) 3 = clipped 3 (-4) 3 := by decide
#check (refuted : ¬Goal)
#check (domain : Domain)
end RevisedBenchmark.ClampGuard
