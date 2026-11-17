module
public import SquareSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastReshapeSquare
open TensorRewrite.Pilot

private theorem reshape_self {n : Nat} {α : Type} (x : Tensor (square n) α)
    (j : Index (square n)) : Reshape.reshapeTensor x (square n) rfl j = x j :=
  congrArg x (LinearIndex.delinearize_linearize (square n) j)

/-- Repeated projection agrees with row-major reshape precisely at empty or singleton squares. -/
theorem squareBoundary : Target := by
  intro n
  constructor
  · intro h
    apply Classical.byContradiction
    intro hn
    let j : Index (square n) := fun a => ⟨a.val, by have := a.isLt; change a.val < n; omega⟩
    let x : Tensor (square n) Nat := fun i => (i 1).val
    have obs := congrFun (h Nat x) j
    rw [reshape_self] at obs
    change 0 = 1 at obs
    contradiction
  · intro small α x
    funext j
    rw [reshape_self]
    apply congrArg x
    funext a
    apply Fin.ext
    have h₁ := (j (duplicate.decode a)).isLt
    have h₂ := (j a).isLt
    change (j (duplicate.decode a)).val = (j a).val
    change _ < n at h₁ h₂
    omega

example : Target := squareBoundary
example : Agreement 0 := (squareBoundary 0).2 (by decide)
example : Agreement 1 := (squareBoundary 1).2 (by decide)
private def pos : Index (square 2) := fun a => a
private def observe : Tensor (square 2) Nat := fun i => (i 1).val
example : projected observe pos = 0 := rfl
example : Reshape.reshapeTensor observe (square 2) rfl pos = 1 := rfl
example : projected observe pos ≠ Reshape.reshapeTensor observe (square 2) rfl pos := by decide
#print axioms squareBoundary
end RevisedBenchmark.BroadcastReshapeSquare
