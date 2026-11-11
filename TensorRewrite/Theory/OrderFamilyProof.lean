module

public import TensorRewrite.Theory.OrderFamily
public import Mathlib.Tactic.Order
public import Mathlib.Tactic.CasesM
public import Mathlib.Tactic.SplitIfs

/-! Rank-general checked order-family identities and complete finite enumeration. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderFamily

open Pilot

/-- Either actual Min operand order has the same exact linear-order value. -/
theorem eval_minOrder {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (reverse : Bool) (left right : Expr) :
    (Expr.minOrder reverse left right).eval (Operations.exact α) inputs =
      Tensor.map₂ min (left.eval (Operations.exact α) inputs)
        (right.eval (Operations.exact α) inputs) := by
  cases reverse <;> funext i <;>
    simp [Expr.minOrder, Expr.eval, Operations.exact, Tensor.map₂, min_comm]

/-- Either actual Max operand order has the same exact linear-order value. -/
theorem eval_maxOrder {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (reverse : Bool) (left right : Expr) :
    (Expr.maxOrder reverse left right).eval (Operations.exact α) inputs =
      Tensor.map₂ max (left.eval (Operations.exact α) inputs)
        (right.eval (Operations.exact α) inputs) := by
  cases reverse <;> funext i <;>
    simp [Expr.maxOrder, Expr.eval, Operations.exact, Tensor.map₂, max_comm]

/-- Every admitted value/predicate rewrite preserves its actual tensor result on its stated
domain. -/
theorem rewrite_sound {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (rule : Rule) (inputs : Nat → Tensor shape α) (condition : rule.Condition inputs) :
    rule.lhs.eval (Operations.exact α) inputs = rule.rhs.eval (Operations.exact α) inputs := by
  cases rule
  all_goals try casesm* Bool, Direction, ZeroComparison
  all_goals simp only [Rule.lhs, Rule.rhs, Graph.eval, eval_minOrder, eval_maxOrder]
  all_goals first | apply congrArg Sum.inl | apply congrArg Sum.inr
  all_goals funext i
  all_goals simp only [Rule.Condition] at condition
  all_goals try specialize condition i
  all_goals dsimp [Expr.eval, Predicate.eval, Operations.exact, Tensor.map₂, Tensor.constant]
  all_goals first
    | change decide (inputs 0 i < 0) = false
      exact decide_eq_false_iff_not.mpr (not_lt_of_ge condition)
    | simp_all [max_def, min_def]
  all_goals try split_ifs
  all_goals try simp_all
  all_goals intros
  all_goals order

/-- The executable pointwise domain check is exactly the declared tensor premise. -/
theorem condition_admitted {α : Type} [LinearOrder α] [Zero α]
    {rank : Nat} {shape : Shape rank} (rule : Rule) (inputs : Nat → Tensor shape α) :
    rule.Condition inputs ↔ ∀ i, rule.admittedAt (fun n => inputs n i) = true := by
  cases rule <;> simp [Rule.Condition, Rule.admittedAt]

/-- Pure result contexts preserve the checked whole-tensor equality, including its result tag. -/
theorem rewrite_in_context {α β : Type} [LinearOrder α] [Zero α]
    {rank : Nat} {shape : Shape rank} (rule : Rule) (inputs : Nat → Tensor shape α)
    (condition : rule.Condition inputs) (context : Tensor shape α ⊕ Tensor shape Bool → β) :
    context (rule.lhs.eval (Operations.exact α) inputs) =
      context (rule.rhs.eval (Operations.exact α) inputs) :=
  congrArg context (rewrite_sound rule inputs condition)

/-- Every constructor/direction/order instance appears in the published list. -/
theorem allRules_complete (rule : Rule) : rule ∈ allRules := by
  cases rule
  all_goals try casesm* Bool, Direction, ZeroComparison
  all_goals simp [allRules]

/-- No stable reporting key is duplicated. -/
theorem allRuleKeys_nodup : (allRules.map Rule.key).Nodup := by decide

/-- The closed order vocabulary has forty-four rule/order/direction instances. -/
theorem rule_count : allRules.length = 44 := by decide

end TensorRewrite.Theory.OrderFamily
