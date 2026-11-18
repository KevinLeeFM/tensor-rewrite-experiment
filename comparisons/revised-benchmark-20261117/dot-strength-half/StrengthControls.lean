import StrengthProof
namespace RevisedBenchmark.DotStrength
example : dot .none x w 0 = 2080 ∧ reduced .none x w 0 = 2082 := by decide
example : dot .lhs x w 1 = 64 ∧ reduced .lhs x w 1 = 64 := by decide
example : dot .rhs x w 1 = 35 ∧ reduced .rhs x w 1 = 35 := by decide
example : half 2079 = 2080 ∧ half 2081 = 2080 := by decide
end RevisedBenchmark.DotStrength
