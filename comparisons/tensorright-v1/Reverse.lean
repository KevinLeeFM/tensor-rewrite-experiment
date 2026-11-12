module

public import TensorRewrite.Theory.ArithmeticFamilyProof

/-! Paper-era Reverse rules, using actual bounded per-axis reversal. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Reverse

open Pilot

/-- `reverse/rule01`: reversal of unit-sized selected axes leaves the tensor unchanged. -/
theorem unit_axes {α : Type} {rank : Nat} {shape : Shape rank} (input : Tensor shape α)
    (axes : Fin rank → Bool) (unitAxes : ∀ axis, axes axis = true → shape axis = 1) :
    Tensor.reverse axes input = input := by
  funext index
  apply congrArg input
  funext axis
  cases h : axes axis with
  | false => simp [Tensor.reverseIndex, h]
  | true =>
    let : Subsingleton (Fin (shape axis)) := by
      rw [unitAxes axis h]
      infer_instance
    exact Subsingleton.elim _ _

/-- `reverse/rule02`: reversal of the same axes twice is identity. -/
theorem involution {α : Type} {rank : Nat} {shape : Shape rank} (input : Tensor shape α)
    (axes : Fin rank → Bool) : Tensor.reverse axes (Tensor.reverse axes input) = input := by
  funext index
  apply congrArg input
  funext axis
  cases h : axes axis <;> simp [Tensor.reverseIndex, h]

/-- `reverse/rule03`: the middle of three disjoint axis groups is reversed twice. -/
theorem overlapping_groups {α : Type} {rank : Nat} {shape : Shape rank} (input : Tensor shape α)
    (first middle last : Fin rank → Bool)
    (firstMiddle : ∀ axis, ¬(first axis = true ∧ middle axis = true))
    (firstLast : ∀ axis, ¬(first axis = true ∧ last axis = true))
    (middleLast : ∀ axis, ¬(middle axis = true ∧ last axis = true)) :
    Tensor.reverse (fun axis => middle axis || last axis)
        (Tensor.reverse (fun axis => first axis || middle axis) input) =
      Tensor.reverse (fun axis => last axis || first axis) input := by
  have masks : (fun axis => (first axis || middle axis) ^^ (middle axis || last axis)) =
      (fun axis => last axis || first axis) := by
    funext axis
    have h₁ := firstMiddle axis
    have h₂ := firstLast axis
    have h₃ := middleLast axis
    cases hFirst : first axis <;> cases hMiddle : middle axis <;> cases hLast : last axis <;>
      simp_all
  have composed (a b : Fin rank → Bool) :
      Tensor.reverse b (Tensor.reverse a input) =
        Tensor.reverse (fun axis => a axis ^^ b axis) input := by
    funext index
    apply congrArg input
    funext axis
    cases ha : a axis <;> cases hb : b axis <;>
      simp [Tensor.reverseIndex, ha, hb]
  simpa only [masks] using composed (fun axis => first axis || middle axis)
    (fun axis => middle axis || last axis)

/-- `reverse/rule04`: reversal commutes with addition of a uniform value. -/
theorem add_constant {α : Type} [Add α] {rank : Nat} {shape : Shape rank}
    (input : Tensor shape α) (axes : Fin rank → Bool) (value : α) :
    Tensor.reverse axes (Tensor.map₂ (· + ·) input (Tensor.constant value)) =
      Tensor.map₂ (· + ·) (Tensor.reverse axes input) (Tensor.constant value) := rfl

#print axioms unit_axes
#print axioms involution
#print axioms overlapping_groups
#print axioms add_constant

end TensorRewrite.PaperComparison.Reverse
