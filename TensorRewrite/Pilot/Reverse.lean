import TensorRewrite.Pilot.IndexLemmas

namespace TensorRewrite.Pilot.Reverse

open Tensor

variable {rank : Nat} {shape : Shape rank} {α : Type} (x : Tensor shape α)

theorem reverse_reverse (axes : Fin rank → Bool) : reverse axes (reverse axes x) = x := by
  funext i
  simp only [reverse, reindex, reverseIndex_reverseIndex]

theorem reverse_comp (a b : Fin rank → Bool) :
    reverse b (reverse a x) = reverse (fun axis => a axis ^^ b axis) x := by
  funext i
  simp only [reverse, reindex, reverseIndex_comp]

theorem reverse_constant (axes : Fin rank → Bool) (value : α) :
    reverse axes (constant value : Tensor shape α) = constant value := rfl

theorem reverse_map₂ (axes : Fin rank → Bool) (f : α → α → α) (y : Tensor shape α) :
    reverse axes (map₂ f x y) = map₂ f (reverse axes x) (reverse axes y) := rfl

theorem reverse_binary_constant_rhs (axes : Fin rank → Bool) (f : α → α → α) (v : α) :
    reverse axes (map₂ f x (constant v)) = map₂ f (reverse axes x) (constant v) := rfl

theorem reverse_binary_constant_lhs (axes : Fin rank → Bool) (f : α → α → α) (v : α) :
    reverse axes (map₂ f (constant v) x) = map₂ f (constant v) (reverse axes x) := rfl

theorem reverse_trivial (axes : Fin rank → Bool)
    (unitAxes : ∀ axis, axes axis = true → shape axis = 1) : reverse axes x = x := by
  funext i
  apply congrArg x
  funext axis
  cases h : axes axis with
  | false => simp [reverseIndex, h]
  | true =>
    letI : Subsingleton (Fin (shape axis)) := by
      rw [unitAxes axis h]
      infer_instance
    exact Subsingleton.elim _ _

/-- Direct list-of-axes form of trivial-axis elimination. -/
theorem reverse_axisMask_trivial (axes : List (Fin rank))
    (unitAxes : ∀ axis, axis ∈ axes → shape axis = 1) : reverse (axisMask axes) x = x := by
  apply reverse_trivial x
  intro axis selected
  exact unitAxes axis (of_decide_eq_true selected)

end TensorRewrite.Pilot.Reverse
