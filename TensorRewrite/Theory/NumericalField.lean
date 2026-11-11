module

public import TensorRewrite.Pilot.OperandOrderLemmas
public import TensorRewrite.Pilot.IndexMaps
public import Mathlib.Algebra.Field.Basic
public import Mathlib.Tactic.Ring

/-! Exact division graphs over a field with totalized inverse, including zero denominators.
These statements instantiate to rationals, reals and complex numbers, not machine integers. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Numerical

open Pilot

variable {α : Type} [Field α] {rank : Nat} {shape : Shape rank}

/-- Division by one preserves every value of an arbitrary finite tensor. -/
theorem divide_one (a : Tensor shape α) : Tensor.map (· / 1) a = a := by
  funext i
  exact div_one _

/-- Exact division is multiplication by a pointwise totalized reciprocal. -/
theorem divide_as_product (a b : Tensor shape α) :
    Tensor.map₂ (· / ·) a b = Tensor.map₂ (· * ·) a (Tensor.map (1 / ·) b) := by
  funext i
  simp [Tensor.map₂, Tensor.map, div_eq_mul_inv]

/-- Division by an exact scalar constant multiplies by its exact reciprocal. -/
theorem divide_constant (a : Tensor shape α) (value : α) :
    Tensor.map₂ (· / ·) a (Tensor.constant value) =
      Tensor.map₂ (· * ·) a (Tensor.constant (1 / value)) := by
  funext i
  simp [Tensor.map₂, Tensor.constant, div_eq_mul_inv]

/-- Division by an explicitly computed reciprocal cancels the double inverse, even at zero. -/
theorem divide_reciprocal (a b : Tensor shape α) :
    Tensor.map₂ (fun x y => x / (1 / y)) a b = Tensor.map₂ (· * ·) a b := by
  funext i
  simp [Tensor.map₂, div_eq_mul_inv]

/-- A quotient of quotients equals the cross product quotient in totalized field arithmetic. -/
theorem divide_fractions (a b c d : Tensor shape α) :
    (fun i => (a i / b i) / (c i / d i)) =
      (fun i => (a i * d i) / (b i * c i)) := by
  funext i
  simp only [div_eq_mul_inv, mul_inv_rev, inv_inv]
  ring

/-- Nested numerator division combines both denominator factors, including zero factors. -/
theorem divide_nested_numerator (a b c : Tensor shape α) :
    (fun i => (a i / b i) / c i) = (fun i => a i / (b i * c i)) := by
  funext i
  simp only [div_eq_mul_inv, mul_inv_rev]
  ring

/-- Nested denominator division moves its denominator to the numerator, including zero. -/
theorem divide_nested_denominator (a b c : Tensor shape α) :
    (fun i => a i / (b i / c i)) = (fun i => (a i * c i) / b i) := by
  funext i
  simp only [div_eq_mul_inv, mul_inv_rev, inv_inv]
  ring

/-- Division by a bounded Broadcast computes the reciprocal before broadcasting it. -/
theorem divide_broadcast {smallRank : Nat} {smallShape : Shape smallRank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (a : Tensor shape α) (small : Tensor smallShape α) :
    Tensor.map₂ (· / ·) a (Tensor.reindex (IndexMaps.broadcastIndex axes extents) small) =
      Tensor.map₂ (· * ·) a
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) (Tensor.map (1 / ·) small)) := by
  funext i
  simp [Tensor.map₂, Tensor.map, Tensor.reindex, div_eq_mul_inv]

/-- Dividing a zero/one predicate embedding by a Broadcast equals the reversed product graph. -/
theorem divide_predicate_broadcast {smallRank : Nat} {smallShape : Shape smallRank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (p : Tensor shape Bool) (small : Tensor smallShape α) :
    Tensor.map₂ (· / ·) (Tensor.map (fun b => if b then (1 : α) else 0) p)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) small) =
      Tensor.map₂ (· * ·)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) (Tensor.map (1 / ·) small))
        (Tensor.map (fun b => if b then (1 : α) else 0) p) := by
  funext i
  simp only [Tensor.map₂, Tensor.map, Tensor.reindex]
  cases p i <;> simp

end TensorRewrite.Theory.Numerical
