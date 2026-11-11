import TensorRewrite.Comparisons.FixedTacticsGuard

run_cmd TensorRewrite.Comparisons.FixedTactics.noCampaignProofs

example : (0 : Nat) = 0 := by rfl
example : (0 : Nat) = 0 := by fixed_simp
example : (0 : Nat) = 0 := by fixed_funext_simp
example : (0 : Nat) = 0 := by fixed_aesop

example (f g : Nat → Nat) (h : ∀ x, f x = g x) : f = g := by fixed_funext_simp
