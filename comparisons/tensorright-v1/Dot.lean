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

#print axioms no_contract

end TensorRewrite.PaperComparison.Dot
