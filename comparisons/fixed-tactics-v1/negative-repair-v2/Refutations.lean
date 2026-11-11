import TensorRewrite.Comparisons.FixedTacticsGuard

run_cmd TensorRewrite.Comparisons.FixedTactics.noCampaignProofs

/-- The arithmetic control proposition is false. -/
theorem invalid_nat_refutation : ¬ ((1 : Nat) + 1 = 3) := by decide

/-- The universally quantified subtraction control is false at one. -/
theorem invalid_int_refutation : ¬ (∀ x : Int, x - x = x) := by
  intro all
  have equal := all 1
  have unequal : ¬ ((1 : Int) - 1 = 1) := by decide
  exact unequal equal

#print axioms invalid_nat_refutation
#print axioms invalid_int_refutation
