import ZeroSpec
namespace RevisedBenchmark.NegatedReduction
theorem identity_iff (s : ZeroSign) : SeedIdentity s ↔ s = true := by
  cases s <;> simp [SeedIdentity, plus]
theorem assoc (a b c : ZeroSign) : plus (plus a b) c = plus a (plus b c) := by
  cases a <;> cases b <;> cases c <;> rfl
theorem refuted : ¬ Preserves := by
  intro h
  have agree := h true ((identity_iff true).mpr rfl) [false, true] (by decide)
  exact (by decide : oldBits true [false, true] ≠ newBits true [false, true]) agree
#print axioms refuted
end RevisedBenchmark.NegatedReduction
