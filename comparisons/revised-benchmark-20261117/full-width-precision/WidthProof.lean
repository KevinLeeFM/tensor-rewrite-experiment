import WidthSpec
namespace RevisedBenchmark.FullWidth
theorem verified : Goal := by
  intro m width I operand
  have full : m = 23 := by omega
  subst m
  funext i
  simp [reduce, Nat.mod_one]
#print axioms verified
end RevisedBenchmark.FullWidth
