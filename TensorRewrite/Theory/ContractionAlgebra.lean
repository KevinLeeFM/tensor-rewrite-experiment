module

public import Mathlib.Algebra.BigOperators.Ring.List
public import TensorRewrite.Pilot.Contraction
public import TensorRewrite.Theory.FiniteSum

/-! Exact contraction distributivity in a semiring, with identity output conversion.
These statements do not supply semiring laws for rounded floating-point operations. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ContractionAlgebra

open Pilot Pilot.Contraction

/-- Contraction distributes over addition of lhs tensors for every valid axis plan. -/
theorem dot_add_left {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x y : Tensor plan.lhsShape α) (z : Tensor plan.rhsShape α) :
    dotTensor plan (· + ·) 0 (· * ·) id (Tensor.map₂ (· + ·) x y) z =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x z)
        (dotTensor plan (· + ·) 0 (· * ·) id y z) := by
  funext output
  simp only [dotTensor, terms, Tensor.map₂, id_eq,
    FiniteSum.foldl_add_eq_sum, zero_add, add_mul]
  exact List.sum_map_add

/-- Contraction distributes over rhs addition without requiring commutative multiplication. -/
theorem dot_add_right {α : Type} [Semiring α] {batch left right contracting : Nat}
    (plan : Plan batch left right contracting)
    (x : Tensor plan.lhsShape α) (y z : Tensor plan.rhsShape α) :
    dotTensor plan (· + ·) 0 (· * ·) id x (Tensor.map₂ (· + ·) y z) =
      Tensor.map₂ (· + ·) (dotTensor plan (· + ·) 0 (· * ·) id x y)
        (dotTensor plan (· + ·) 0 (· * ·) id x z) := by
  funext output
  simp only [dotTensor, terms, Tensor.map₂, id_eq,
    FiniteSum.foldl_add_eq_sum, zero_add, mul_add]
  exact List.sum_map_add

end TensorRewrite.Theory.ContractionAlgebra
