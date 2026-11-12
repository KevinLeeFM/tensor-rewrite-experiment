module

public import TensorRewrite.Pilot.ContractionRules
public import Mathlib.Algebra.Group.Defs

/-! Paper-era contraction rules on actual bounded batch, free and contraction axes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Dot

open Pilot Pilot.Contraction

/-- `dot/rule04`: an empty set of contracting axes is broadcasted multiplication. -/
theorem no_contract {α : Type} [Mul α] [AddZeroClass α] {batch left right : Nat}
    (plan : Plan batch left right 0) (lhs : Tensor plan.lhsShape α)
    (rhs : Tensor plan.rhsShape α) :
    dotTensor plan (· + ·) 0 (· * ·) id lhs rhs =
      outerTensor plan (· * ·) id lhs rhs :=
  dot_no_contract plan (· + ·) 0 (· * ·) id (fun value => zero_add value) lhs rhs

/-- A zero-sized axis leaves no bounded index, so its shape has zero elements. -/
theorem empty_axis_count {rank : Nat} (shape : Shape rank) (axis : Fin rank)
    (empty : shape axis = 0) : LinearIndex.elementCount shape = 0 := by
  by_cases zero : LinearIndex.elementCount shape = 0
  · exact zero
  · let index := LinearIndex.delinearize shape ⟨0, Nat.pos_of_ne_zero zero⟩
    have bound := (index axis).isLt
    omega

/-- A zero axis remains present when its group is concatenated with another shape. -/
theorem append_zero_left {left right : Nat} (a : Shape left) (b : Shape right)
    (empty : ∃ axis, a axis = 0) : ∃ axis, appendShape a b axis = 0 := by
  obtain ⟨axis, zero⟩ := empty
  exact ⟨axis.castAdd right, by simpa [appendShape] using zero⟩

theorem append_zero_right {left right : Nat} (a : Shape left) (b : Shape right)
    (empty : ∃ axis, b axis = 0) : ∃ axis, appendShape a b axis = 0 := by
  obtain ⟨axis, zero⟩ := empty
  exact ⟨axis.natAdd left, by simpa [appendShape] using zero⟩

/-- The paper's zero batch/free/contract groups imply an empty output or contraction. -/
theorem grouped_empty {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (empty : (∃ axis, plan.batchShape axis = 0) ∨ (∃ axis, plan.leftShape axis = 0) ∨
      (∃ axis, plan.rightShape axis = 0) ∨ (∃ axis, plan.contractShape axis = 0)) :
    (∃ axis, plan.outputShape axis = 0) ∨ (∃ axis, plan.contractShape axis = 0) := by
  rcases empty with batchZero | leftZero | rightZero | contractZero
  · left
    exact append_zero_left _ _ batchZero
  · left
    exact append_zero_right _ _ (append_zero_left _ _ leftZero)
  · left
    exact append_zero_right _ _ (append_zero_right _ _ rightZero)
  · exact Or.inr contractZero

/-- `dot/rule05`: a zero output or contracted dimension gives the zero tensor. -/
theorem empty_dimension {α : Type} [Mul α] [AddZeroClass α]
    {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    (lhs : Tensor plan.lhsShape α) (rhs : Tensor plan.rhsShape α)
    (empty : (∃ axis, plan.outputShape axis = 0) ∨
      (∃ axis, plan.contractShape axis = 0)) :
    dotTensor plan (· + ·) 0 (· * ·) id lhs rhs = Tensor.constant 0 := by
  rcases empty with ⟨axis, zero⟩ | ⟨axis, zero⟩
  · exact dot_empty_output plan (· + ·) 0 (· * ·) id lhs rhs
      (empty_axis_count plan.outputShape axis zero)
  · exact dot_empty_contract plan (· + ·) 0 (· * ·) id lhs rhs
      (empty_axis_count plan.contractShape axis zero)

#print axioms append_zero_left
#print axioms append_zero_right
#print axioms grouped_empty
#print axioms empty_axis_count
#print axioms empty_dimension
#print axioms no_contract

end TensorRewrite.PaperComparison.Dot
