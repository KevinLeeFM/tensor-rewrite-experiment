import PadSpec
set_option autoImplicit false
namespace Auxiliary.DebugPad

private theorem span_zero (s : Int) : span s 0 = s := by simp [span]

/-- Membership in an occupied source row implies the outer edge mask admits it. -/
private theorem nestedMask (s l h t u q : Int) (hl : 0 ≤ l) (hh : 0 ≤ h) :
    occupied s (l+u) t q ↔ occupied (l+h+span s t) u 0 q ∧ occupied s l t (q-u) := by
  have regroup : q-u-l = q-(l+u) := by omega
  simp only [occupied, span_zero, Int.zero_add, Int.emod_one, and_true, regroup]
  omega

theorem verified : nestedGoal := by
  intro r s l h t u v hyp
  dsimp only
  intro _nonnegative
  constructor
  · funext i
    simp only [extent, zero, plus, span_zero]
    omega
  · intro α z x q _valid
    by_cases rhs : ∀ i, decide (occupied (s i) (plus l u i) (t i) (q i)) = true
    · have ho : ∀ i, decide (occupied (extent s l h t i) (u i) (zero i) (q i)) = true := by
        intro i
        exact decide_eq_true ((nestedMask _ _ _ _ _ _ (hyp i).2.1 (hyp i).2.2.1).mp (of_decide_eq_true (rhs i))).1
      have hi : ∀ i, decide (occupied (s i) (l i) (t i) (q i-u i)) = true := by
        intro i
        exact decide_eq_true ((nestedMask _ _ _ _ _ _ (hyp i).2.1 (hyp i).2.2.1).mp (of_decide_eq_true (rhs i))).2
      simp only [zero] at ho
      unfold pad
      simp only [ite_eq_left ho, ite_eq_left rhs, zero, Int.zero_add, Int.ediv_one, ite_eq_left hi]
      apply congrArg x
      funext i
      congr 1
      simp only [plus]
      omega
    · unfold pad
      rw [ite_eq_right rhs]
      split
      next ho =>
        simp only [zero, Int.zero_add, Int.ediv_one]
        apply ite_eq_right
        intro hi
        apply rhs
        intro i
        exact decide_eq_true ((nestedMask _ _ _ _ _ _ (hyp i).2.1 (hyp i).2.2.1).mpr
          ⟨of_decide_eq_true (ho i), of_decide_eq_true (hi i)⟩)
      next => rfl

theorem low_verified : lowGoal := by
  intro r s l u hyp
  constructor
  · funext i; simp [plus,Int.add_assoc]
  · intro α z x q _valid
    unfold padLow
    by_cases hr : ∀ i, plus l u i ≤ q i
    · have ho : ∀ i, u i ≤ q i := by intro i; have := hr i; have := (hyp i).2.1; unfold plus at *; omega
      have hi : ∀ i, l i ≤ q i-u i := by intro i; have := hr i; unfold plus at *; omega
      rw [ite_eq_left hr,ite_eq_left ho,ite_eq_left hi]
      apply congrArg x; funext i; change q i-u i-l i = q i-(l i+u i); omega
    · rw [ite_eq_right hr]
      split
      next ho =>
        apply ite_eq_right
        intro hi
        apply hr
        intro i
        have h : l i ≤ q i - u i := hi i
        unfold plus
        omega
      next => rfl
/-- A live Pad sample always indexes an actual original element. -/
theorem read_bound (s l h q : Int) (hs : 0 ≤ s) (hh : 0 ≤ h)
    (hx : occupied s l h q) : 0 ≤ (q-l)/(h+1) ∧ (q-l)/(h+1) < s := by
  obtain ⟨lo, hi, _⟩ := hx
  have pos : 0 < h+1 := by omega
  refine ⟨Int.ediv_nonneg (by omega) (by omega), (Int.ediv_lt_iff_lt_mul pos).mpr ?_⟩
  by_cases e : s = 0
  · subst s
    unfold span at hi
    rw [(by decide : max (0:Int) (0-1) = 0), Int.zero_mul] at hi
    omega
  · have hmax : max 0 (s-1) = s-1 := Int.max_eq_right (by omega)
    simp only [span, hmax, Int.sub_mul, Int.one_mul] at hi
    rw [Int.mul_add, Int.mul_one]
    omega
#print axioms read_bound
#print axioms verified
#print axioms low_verified
end Auxiliary.DebugPad
