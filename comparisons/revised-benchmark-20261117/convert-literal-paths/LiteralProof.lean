import LiteralSpec
namespace RevisedBenchmark.LiteralConvert

theorem fold_verified : FoldingGoal := by
  intro dims α β convertLiteral v
  cases h : convertLiteral v <;> simp [foldConstant, eval, h]

theorem identity_verified : IdentityGoal := by
  intro dims α v
  rfl

#print axioms fold_verified
#print axioms identity_verified
end RevisedBenchmark.LiteralConvert
