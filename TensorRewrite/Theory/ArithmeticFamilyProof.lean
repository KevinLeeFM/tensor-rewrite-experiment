module

public import TensorRewrite.Theory.ArithmeticFamily
public import Mathlib.Tactic.Ring
public import Mathlib.Tactic.SplitIfs
public import Mathlib.Basic.Real.Basic
public import Mathlib.Basic.Complex.Basic

/-! Complete rank-general arithmetic values for exact commutative rings and modular words. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ArithmeticFamily

open Pilot

/-- Exact commutative addition normalizes either actual matched sum order. -/
theorem eval_addOrder {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool)
    (reverse : Bool) (left right : Expr) :
    (Expr.addOrder reverse left right).eval (Operations.exact α) inputs predicates =
      Tensor.map₂ (· + ·) (left.eval (Operations.exact α) inputs predicates)
        (right.eval (Operations.exact α) inputs predicates) := by
  cases reverse <;> funext index <;> simp [Expr.addOrder, Expr.eval, Operations.exact, Tensor.map₂,
    add_comm]

/-- Exact commutative multiplication normalizes either actual matched product order. -/
theorem eval_mulOrder {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool)
    (reverse : Bool) (left right : Expr) :
    (Expr.mulOrder reverse left right).eval (Operations.exact α) inputs predicates =
      Tensor.map₂ (· * ·) (left.eval (Operations.exact α) inputs predicates)
        (right.eval (Operations.exact α) inputs predicates) := by
  cases reverse <;> funext index <;> simp [Expr.mulOrder, Expr.eval, Operations.exact, Tensor.map₂,
    mul_comm]

/-- Every admitted arithmetic tree rewrite preserves all pure tensor values in any actual
commutative ring. No constant-recognition, no-overflow or nonempty-shape premise is needed. -/
theorem rewrite_sound {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (rule : Rule) (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    rule.lhs.eval (Operations.exact α) inputs predicates =
      rule.rhs.eval (Operations.exact α) inputs predicates := by
  cases rule <;> funext index <;>
    simp only [Rule.lhs, Rule.rhs, eval_addOrder, eval_mulOrder, Expr.eval,
      Tensor.map, Tensor.map₂, Tensor.constant]
  all_goals dsimp only [Operations.exact]
  all_goals try split_ifs
  all_goals ring

/-- Pure contexts of any result type preserve the checked arithmetic equality. Effects and
schedules are separate observations and are not supplied by this congruence theorem. -/
theorem rewrite_in_context {α β : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (rule : Rule) (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool)
    (context : Tensor shape α → β) :
    context (rule.lhs.eval (Operations.exact α) inputs predicates) =
      context (rule.rhs.eval (Operations.exact α) inputs predicates) :=
  congrArg context (rewrite_sound rule inputs predicates)

/-- The explicit family enumeration includes every constructor and every Boolean matcher order. -/
theorem allRules_complete (rule : Rule) : rule ∈ allRules := by decide +revert

/-- No reporting key is duplicated; distinct matcher orders remain separately measurable. -/
theorem allRuleKeys_nodup : (allRules.map Rule.key).Nodup := by decide

/-- The declared scalar rule family contains exactly forty-three profiles. -/
theorem rule_count : allRules.length = 43 := by decide

/-- Exact integer tensor values instantiate the complete family. -/
theorem integer_family {rank : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape Int) (predicates : Nat → Tensor shape Bool) :
    rule.lhs.eval (Operations.exact Int) inputs predicates =
      rule.rhs.eval (Operations.exact Int) inputs predicates := rewrite_sound rule inputs predicates

/-- Exact real values instantiate the same family without rounded arithmetic assumptions. -/
theorem real_family {rank : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape ℝ) (predicates : Nat → Tensor shape Bool) :
    rule.lhs.eval (Operations.exact ℝ) inputs predicates =
      rule.rhs.eval (Operations.exact ℝ) inputs predicates := rewrite_sound rule inputs predicates

/-- Exact complex values instantiate the same family; no transcendental branch law is used. -/
theorem complex_family {rank : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape ℂ) (predicates : Nat → Tensor shape Bool) :
    rule.lhs.eval (Operations.exact ℂ) inputs predicates =
      rule.rhs.eval (Operations.exact ℂ) inputs predicates := rewrite_sound rule inputs predicates

/-- Mathlib's actual word ring instance proves every family rule at all widths, including zero
and overflowing intermediate arithmetic, without a no-wrap premise. -/
theorem word_family {rank width : Nat} {shape : Shape rank} (rule : Rule)
    (inputs : Nat → Tensor shape (BitVec width)) (predicates : Nat → Tensor shape Bool) :
    rule.lhs.eval (Operations.exact (BitVec width)) inputs predicates =
      rule.rhs.eval (Operations.exact (BitVec width)) inputs predicates :=
  rewrite_sound rule inputs predicates

end TensorRewrite.Theory.ArithmeticFamily
