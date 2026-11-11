module

public import Mathlib.Algebra.BigOperators.Group.Finset.Basic
public import Mathlib.Algebra.BigOperators.Group.Finset.Sigma
public import Mathlib.Data.Fintype.Pi
public import TensorRewrite.Pilot.ReshapeLemmas
public import TensorRewrite.Pilot.Reduction

/-! Exact finite-sum theory for commutative additive monoids. IEEE floating addition
is not supplied with this algebraic structure. This module makes no statement about C++ code. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.FiniteSum

open Pilot Pilot.LinearIndex Pilot.Reshape

/-- An ordered additive fold equals its initializer plus the list sum. -/
theorem foldl_add_eq_sum {α : Type} [AddMonoid α] (values : List α) (initial : α) :
    values.foldl (· + ·) initial = initial + values.sum := by
  induction values generalizing initial with
  | nil => simp
  | cons value values ih =>
    simp only [List.foldl_cons, List.sum_cons]
    rw [ih, add_assoc]

/-- The existing ordered reduction model is a fiber sum for additive monoids. -/
theorem reduce_add_eq_fiber_sum {α : Type} [AddMonoid α] (plan : Reduction.Plan)
    (input : Tensor plan.inputShape α) :
    Reduction.reduceTensor plan (· + ·) 0 input =
      fun output => (Reduction.fiberValues plan input output).sum := by
  funext output
  exact (foldl_add_eq_sum _ 0).trans (zero_add _)

/-- Logical coordinates and bounded linear positions are equivalent even for empty shapes. -/
def indexEquiv {rank : Nat} (shape : Shape rank) : Index shape ≃ Fin (elementCount shape) where
  toFun := linearize shape
  invFun := delinearize shape
  left_inv := delinearize_linearize shape
  right_inv := linearize_delinearize shape

/-- A count-preserving reshape gives an equivalence from output coordinates to input coordinates. -/
def reshapeEquiv {inputRank outputRank : Nat} (inputShape : Shape inputRank)
    (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) :
    Index outputShape ≃ Index inputShape :=
  (indexEquiv outputShape).trans ((finCongr sameCount.symm).trans (indexEquiv inputShape).symm)

/-- The equivalence computes precisely the previously defined logical reshape index. -/
theorem reshapeEquiv_apply {inputRank outputRank : Nat} (inputShape : Shape inputRank)
    (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) (index : Index outputShape) :
    reshapeEquiv inputShape outputShape sameCount index =
      reshapeIndex inputShape outputShape sameCount index := rfl

/-- Summing all tensor elements is invariant under any equal-count logical reshape. -/
theorem sum_reshape {α : Type} [AddCommMonoid α] {inputRank outputRank : Nat}
    {inputShape : Shape inputRank} (input : Tensor inputShape α)
    (outputShape : Shape outputRank)
    (sameCount : elementCount inputShape = elementCount outputShape) :
    (∑ index : Index outputShape, reshapeTensor input outputShape sameCount index) =
      ∑ index : Index inputShape, input index := by
  exact Equiv.sum_comp (reshapeEquiv inputShape outputShape sameCount) input

/-- Two finite reduction axes can exchange order under the explicit commutative-monoid law. -/
theorem sum_swap {α I J : Type} [AddCommMonoid α] [Fintype I] [Fintype J]
    (input : I → J → α) : (∑ i, ∑ j, input i j) = ∑ j, ∑ i, input i j :=
  Finset.sum_comm

/-- Two exact reductions fuse by pointwise addition, without a nonempty-domain premise. -/
theorem sum_add {α I : Type} [AddCommMonoid α] [Fintype I] (x y : I → α) :
    (∑ i, x i) + (∑ i, y i) = ∑ i, (x i + y i) :=
  (Finset.sum_add_distrib).symm

end TensorRewrite.Theory.FiniteSum
