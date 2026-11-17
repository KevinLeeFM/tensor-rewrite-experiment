module
public import ScalarSelectSpec

public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarSelect
open TensorRewrite.Pilot.SelectContraction (sum)

/-- Independent singleton choices force both factors to equal their product. -/
theorem boundary : Boundary := by
  intro a b
  constructor
  · intro allCells
    have left := allCells [⟨true, 1, 0⟩]
    have right := allCells [⟨false, 0, 1⟩]
    simp [original, replaced, sum] at left right
    have eq : a = b := left.trans right.symm
    subst b
    have zeroProduct : a * (a - 1) = 0 := by rw [Int.mul_sub, Int.mul_one, ← left]; omega
    rcases Int.mul_eq_zero.mp zeroProduct with zero | one
    · exact Or.inl ⟨zero,zero⟩
    · exact Or.inr ⟨by omega, by omega⟩
  · rintro (⟨rfl,rfl⟩ | ⟨rfl,rfl⟩) cells
    · induction cells with
      | nil => rfl
      | cons c cs ih =>
        simpa [original, replaced, sum] using ih
    · simp [original, replaced]

example : original 2 3 [⟨true, 1, 99⟩, ⟨false, 55, 2⟩] = 8 ∧
    replaced 2 3 [⟨true, 1, 99⟩, ⟨false, 55, 2⟩] = 18 := by decide
example : original (-1) (-1) [⟨true, 2, 0⟩] ≠ replaced (-1) (-1) [⟨true, 2, 0⟩] := by decide
example : original 2 3 [] = replaced 2 3 [] := by decide

#check (boundary : Boundary)
#print axioms boundary
end RevisedBenchmark.ScalarSelect
