import DeleteSpec
set_option autoImplicit false
namespace RevisedBenchmark.DeleteUpdate
def base (j : Fin 3) : Int := 4 + j.val
def noRow (i : Fin 0) (_ : Fin 2) : Int := nomatch i
theorem refuted : ¬ Case := by
  intro h
  have eq := h 3 0 2 (by decide) (by decide) (by decide) base noRow
  exact (by decide : original 3 0 2 base noRow ≠ replacement 3 0 2 base noRow) eq
theorem shapeBoundary (u v : Nat) (fits : u ≤ 1) :
    [u,v].prod = [v].prod ↔ u = 1 ∨ v = 0 := by
  rcases (show u = 0 ∨ u = 1 by omega) with h | h <;> subst u <;> simp [eq_comm]
example : ¬ Case := refuted
#print axioms refuted
#print axioms shapeBoundary
end RevisedBenchmark.DeleteUpdate
