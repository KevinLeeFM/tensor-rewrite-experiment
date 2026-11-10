module

public import TensorRewrite.Pilot.Indexing

/-! Pointwise modular arithmetic for arbitrary finite shapes and bit widths.
These laws do not specify floating-point permissions or mutable HLO behavior. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ModularArithmetic

open Tensor

variable {rank : Nat} {shape : Shape rank} {width : Nat}
  (x y z a b : Tensor shape (BitVec width))

/-- A modular Add with zero at the rhs preserves the other value. -/
theorem add_rhs_zero : map₂ (· + ·) x (constant (0#width)) = x := by
  funext index
  exact BitVec.add_zero (x index)

/-- A modular Add with zero at the lhs preserves the other value. -/
theorem add_lhs_zero : map₂ (· + ·) (constant (0#width)) x = x := by
  funext index
  exact BitVec.zero_add (x index)

/-- Constants may move to the rhs because modular Add is commutative. -/
theorem add_comm : map₂ (· + ·) x y = map₂ (· + ·) y x := by
  funext index
  exact BitVec.add_comm (x index) (y index)

/-- Modular Add reassociates even when intermediate values overflow. -/
theorem add_assoc : map₂ (· + ·) (map₂ (· + ·) x y) z =
    map₂ (· + ·) x (map₂ (· + ·) y z) := by
  funext index
  exact BitVec.add_assoc (x index) (y index) (z index)

/-- A modular subtraction followed by addition can gather the two constants. -/
theorem sub_add_constant : map₂ (· + ·) (map₂ (· - ·) y x) z =
    map₂ (· - ·) (map₂ (· + ·) y z) x := by
  funext index
  change (y index - x index) + z index = (y index + z index) - x index
  simp only [BitVec.sub_eq_add_neg, BitVec.add_assoc]
  rw [BitVec.add_comm (-x index) (z index)]

/-- Cancellation when the subtracted expression is the rhs Add operand. -/
theorem add_sub_cancel_right : map₂ (· + ·) x (map₂ (· - ·) y x) = y := by
  funext index
  change x index + (y index - x index) = y index
  rw [BitVec.add_comm, BitVec.sub_add_cancel]

/-- Cancellation when the subtracted expression is the lhs Add operand. -/
theorem add_sub_cancel_left : map₂ (· + ·) (map₂ (· - ·) y x) x = y := by
  funext index
  exact BitVec.sub_add_cancel (y index) (x index)

/-- Multiplication by a rhs modular zero yields zero. -/
theorem mul_rhs_zero : map₂ (· * ·) x (constant (0#width)) = constant (0#width) := by
  funext index
  exact BitVec.mul_zero

/-- Multiplication by a lhs modular zero yields zero. -/
theorem mul_lhs_zero : map₂ (· * ·) (constant (0#width)) x = constant (0#width) := by
  funext index
  exact BitVec.zero_mul

/-- A rhs modular one is an identity, including the degenerate zero-width model. -/
theorem mul_rhs_one : map₂ (· * ·) x (constant (1#width)) = x := by
  funext index
  exact BitVec.mul_one (x index)

/-- A lhs modular one is an identity. -/
theorem mul_lhs_one : map₂ (· * ·) (constant (1#width)) x = x := by
  funext index
  exact BitVec.one_mul (x index)

/-- Negating both operands leaves a modular product unchanged. -/
theorem mul_neg_neg : map₂ (· * ·) (map Neg.neg x) (map Neg.neg y) = map₂ (· * ·) x y := by
  funext index
  exact BitVec.neg_mul_neg (x index) (y index)

/-- Modular products reassociate without a no-overflow hypothesis. -/
theorem mul_assoc : map₂ (· * ·) (map₂ (· * ·) x y) z =
    map₂ (· * ·) x (map₂ (· * ·) y z) := by
  funext index
  exact BitVec.mul_assoc (x index) (y index) (z index)

/-- Gather a common rhs factor in a modular sum of products. -/
theorem factor_right : map₂ (· + ·) (map₂ (· * ·) x z) (map₂ (· * ·) y z) =
    map₂ (· * ·) (map₂ (· + ·) x y) z := by
  funext index
  exact BitVec.add_mul.symm

/-- Gather a common lhs factor, placing it on the rhs of the result. -/
theorem factor_left : map₂ (· + ·) (map₂ (· * ·) z x) (map₂ (· * ·) z y) =
    map₂ (· * ·) (map₂ (· + ·) x y) z := by
  funext index
  change z index * x index + z index * y index = (x index + y index) * z index
  rw [BitVec.mul_comm (z index), BitVec.mul_comm (z index), ← BitVec.add_mul]

/-- Four modular factors may be regrouped into two pairs. -/
theorem four_factors : map₂ (· * ·) (map₂ (· * ·) x a) (map₂ (· * ·) y b) =
    map₂ (· * ·) (map₂ (· * ·) x y) (map₂ (· * ·) a b) := by
  funext index
  change (x index * a index) * (y index * b index) =
    (x index * y index) * (a index * b index)
  rw [BitVec.mul_assoc, ← BitVec.mul_assoc (a index), BitVec.mul_comm (a index) (y index),
    BitVec.mul_assoc, ← BitVec.mul_assoc]

end TensorRewrite.Pilot.ModularArithmetic
