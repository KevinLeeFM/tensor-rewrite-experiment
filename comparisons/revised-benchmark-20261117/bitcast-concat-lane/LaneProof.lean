import LaneSpec
set_option autoImplicit false
namespace RevisedBenchmark.LaneConcat

private theorem last_concat (copies r : Nat) (hc : copies ≠ 0) (s : List Nat) :
    concat copies s.length (s ++ [r]) = some (s ++ [copies*r]) := by
  induction s with
  | nil => simp [concat,hc]
  | cons x s ih =>
    simp [concat,hc] at ih ⊢

theorem admissible (r copies : Nat) (hr : 1 < r) (s out : List Nat) :
    before r copies s = some out ↔ copies = 1 ∧ out = s := by
  by_cases z : copies = 0
  · subst copies; simp [before,concat]
  · rw [before,last_concat _ _ z]
    by_cases n : copies*r = r
    · have one : copies = 1 := Nat.eq_of_mul_eq_mul_right (by omega : 0 < r)
          (show copies*r = 1*r by simpa using n)
      simp [n,one,eq_comm]
    · have ne : copies ≠ 1 := by intro h; simp [h] at n
      simp [n,ne]

theorem outsideRank (copies : Nat) (s : List Nat) : after copies s = none := by
  simp [after,concat]
theorem refuted : ¬ Preservation := by
  intro h
  have impossible := h 2 1 [3] [3] (by decide)
    ((admissible 2 1 (by decide) _ _).2 ⟨rfl,rfl⟩)
  rw [outsideRank] at impossible
  contradiction
#print axioms admissible
#print axioms refuted
end RevisedBenchmark.LaneConcat
