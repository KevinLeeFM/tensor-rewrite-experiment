import UpdateSpec
namespace RevisedBenchmark.UpdateConstantPad
theorem clamp (e w : Nat) (fit : w ≤ e) (s : Int) :
    start e w s = (low e w s : Int) := by
  unfold start low
  omega
theorem verified : Goal := by
  intro r e w fit s
  have st (j : Fin r) := clamp (e j) (w j) (fit j) (s j)
  constructor
  · intro j
    unfold high low
    have h := fit j
    omega
  · intro α fill read
    funext o
    unfold update padded
    simp only [st]
    split <;> rename_i h
    · rw [ite_eq_left (fun j => by have b := h j; omega)]
      congr 1
      funext j
      have b := h j
      omega
    · rw [ite_eq_right (by intro g; apply h; intro j; have b := g j; omega)]
/-- Every source-side selected local coordinate is in the declared update width. -/
theorem selectedBound (e w o : Nat) (s : Int)
    (left : start e w s ≤ o) (right : (o : Int) < start e w s + w) :
    ((o : Int) - start e w s).toNat < w := by omega
#print axioms selectedBound
#print axioms verified
end RevisedBenchmark.UpdateConstantPad
