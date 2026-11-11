module

public import TensorRewrite.Theory.OrderFamilyProof
public import TensorRewrite.Theory.OrderWord
public import Mathlib.Basic.Real.Basic

/-! Four concrete scalar tracks for the complete declared order family. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderFamily

open Pilot

/-- Exact integer values instantiate every order rule on its explicit mathematical domain. -/
theorem integer_family {rank : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape Int) (condition : rule.Condition inputs) :
    rule.lhs.eval (Operations.exact Int) inputs = rule.rhs.eval (Operations.exact Int) inputs :=
  rewrite_sound rule inputs condition

/-- Exact real values instantiate every order rule, without NaNs or signed-zero bit distinctions. -/
theorem real_family {rank : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape ℝ) (condition : rule.Condition inputs) :
    rule.lhs.eval (Operations.exact ℝ) inputs = rule.rhs.eval (Operations.exact ℝ) inputs :=
  rewrite_sound rule inputs condition

/-- Unsigned comparison of actual stored words instantiates all rules at every width. -/
theorem unsigned_family {rank : Nat} {shape : Shape rank} (width : Nat) (rule : Rule)
    (inputs : Nat → Tensor shape (Word false width)) (condition : rule.Condition inputs) :
    rule.lhs.eval (Operations.exact (Word false width)) inputs =
      rule.rhs.eval (Operations.exact (Word false width)) inputs :=
  rewrite_sound rule inputs condition

/-- Signed two's-complement comparison instantiates all rules, including width zero. -/
theorem signed_family {rank : Nat} {shape : Shape rank} (width : Nat) (rule : Rule)
    (inputs : Nat → Tensor shape (Word true width)) (condition : rule.Condition inputs) :
    rule.lhs.eval (Operations.exact (Word true width)) inputs =
      rule.rhs.eval (Operations.exact (Word true width)) inputs :=
  rewrite_sound rule inputs condition

/-- Every unsigned word is nonnegative; the zero-comparison domain is discharged at all widths. -/
theorem unsigned_nonnegative {width : Nat} (value : Word false width) : 0 ≤ value := by
  change (0 : Int) ≤ Int.ofNat value.bits.toNat
  exact Int.natCast_nonneg _

/-- All four zero-comparison rules therefore apply to every unsigned tensor without a value guard.
-/
theorem unsigned_zero {rank : Nat} {shape : Shape rank} (width : Nat)
    (direction : ZeroComparison) (inputs : Nat → Tensor shape (Word false width)) :
    (Rule.compareZero direction).lhs.eval (Operations.exact (Word false width)) inputs =
      (Rule.compareZero direction).rhs.eval (Operations.exact (Word false width)) inputs := by
  apply unsigned_family width
  exact fun i => unsigned_nonnegative (inputs 0 i)

end TensorRewrite.Theory.OrderFamily
