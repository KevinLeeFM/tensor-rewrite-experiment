module

public import TensorRewrite.Pilot.Tensor
public import Mathlib.Order.Basic

/-! A closed family of exact linear-order value/comparison graphs. The evaluator assumes no
order laws. The selected proof interpretation supplies a genuine linear order and explicit
domains. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderFamily

open Pilot

/-- Six scalar comparison directions; equality here is equality of exact ordered values. -/
inductive Direction where
  | lt | le | gt | ge | eq | ne
deriving DecidableEq, Repr

/-- Four comparisons between an input and zero, keeping the actual operand orientation. -/
inductive ZeroComparison where
  | inputLtZero | zeroGtInput | inputGeZero | zeroLeInput
deriving DecidableEq, Repr

/-- Scalar operations interpreted by the graph evaluator, without any assumed algebraic laws. -/
structure Operations (α : Type) where
  zero : α
  minimum : α → α → α
  maximum : α → α → α
  compare : Direction → α → α → Bool

/-- Exact ordered operations; zero is distinguished but need not be the least element. -/
def Operations.exact (α : Type) [LinearOrder α] [Zero α] : Operations α where
  zero := 0
  minimum := min
  maximum := max
  compare
    | .lt => fun a b => decide (a < b)
    | .le => fun a b => decide (a ≤ b)
    | .gt => fun a b => decide (b < a)
    | .ge => fun a b => decide (b ≤ a)
    | .eq => fun a b => decide (a = b)
    | .ne => fun a b => decide (a ≠ b)

/-- Shape-preserving ordered expressions with shared input references and a defined clamp graph. -/
inductive Expr where
  | input (number : Nat)
  | zero
  | minimum (left right : Expr)
  | maximum (left right : Expr)
  | clamp (lower value upper : Expr)
deriving Repr

/-- Exact original Min operand order, preserved in the expression tree. -/
def Expr.minOrder (reverse : Bool) (left right : Expr) : Expr :=
  if reverse then .minimum right left else .minimum left right

/-- Exact original Max operand order, preserved in the expression tree. -/
def Expr.maxOrder (reverse : Bool) (left right : Expr) : Expr :=
  if reverse then .maximum right left else .maximum left right

/-- Evaluate value expressions; Clamp is Min(Max(value,lower),upper), including reversed bounds. -/
def Expr.eval {α : Type} {rank : Nat} {shape : Shape rank} (ops : Operations α)
    (inputs : Nat → Tensor shape α) : Expr → Tensor shape α
  | .input n => inputs n
  | .zero => Tensor.constant ops.zero
  | .minimum x y => Tensor.map₂ ops.minimum (x.eval ops inputs) (y.eval ops inputs)
  | .maximum x y => Tensor.map₂ ops.maximum (x.eval ops inputs) (y.eval ops inputs)
  | .clamp lo x hi => Tensor.map₂ ops.minimum
      (Tensor.map₂ ops.maximum (x.eval ops inputs) (lo.eval ops inputs)) (hi.eval ops inputs)

/-- Predicate graphs contain explicit ordered comparisons and Boolean conjunction. -/
inductive Predicate where
  | constant (value : Bool)
  | compare (direction : Direction) (left right : Expr)
  | and (left right : Predicate)
deriving Repr

/-- Interpret comparisons and conjunction without changing the tensor shape. -/
def Predicate.eval {α : Type} {rank : Nat} {shape : Shape rank} (ops : Operations α)
    (inputs : Nat → Tensor shape α) : Predicate → Tensor shape Bool
  | .constant value => Tensor.constant value
  | .compare direction x y => Tensor.map₂ (ops.compare direction)
      (x.eval ops inputs) (y.eval ops inputs)
  | .and x y => Tensor.map₂ (· && ·) (x.eval ops inputs) (y.eval ops inputs)

/-- A graph has either a value-tensor result or a predicate-tensor result. -/
inductive Graph where
  | value (expression : Expr)
  | predicate (expression : Predicate)
deriving Repr

/-- The sum tags preserve the graph's result type at the whole-tensor level. -/
def Graph.eval {α : Type} {rank : Nat} {shape : Shape rank} (ops : Operations α)
    (inputs : Nat → Tensor shape α) : Graph → Tensor shape α ⊕ Tensor shape Bool
  | .value expression => .inl (expression.eval ops inputs)
  | .predicate expression => .inr (expression.eval ops inputs)

/-- Closed rewrite vocabulary, including all matched orders and all six self comparisons. -/
inductive Rule where
  | maxSelf | minSelf
  | maxExtreme (reverse : Bool) | minExtreme (reverse : Bool)
  | maxNestedLeft (repeatFirst : Bool) | minNestedLeft (repeatFirst : Bool)
  | maxNestedRight (repeatFirst : Bool) | minNestedRight (repeatFirst : Bool)
  | maxMinClamp (outer inner : Bool) | minMaxClamp (outer inner : Bool)
  | maxClampLower (reverse : Bool)
  | compareSelf (direction : Direction)
  | compareZero (direction : ZeroComparison)
  | maxCompareFirst | maxCompareSecond | minCompareFirst | minCompareSecond
  | tautological (firstReverse secondReverse : Bool)
  | clampIdempotent | clampRange
deriving DecidableEq, Repr

/-- The explicitly retained original value or predicate tree for each rule. -/
def Rule.lhs : Rule → Graph
  | .maxSelf => .value (.maximum (.input 0) (.input 0))
  | .minSelf => .value (.minimum (.input 0) (.input 0))
  | .maxExtreme reverse => .value (.maxOrder reverse (.input 0) (.input 1))
  | .minExtreme reverse => .value (.minOrder reverse (.input 0) (.input 1))
  | .maxNestedLeft first => .value (.maximum (.maximum (.input 0) (.input 1))
      (.input (if first then 0 else 1)))
  | .minNestedLeft first => .value (.minimum (.minimum (.input 0) (.input 1))
      (.input (if first then 0 else 1)))
  | .maxNestedRight first => .value (.maximum (.input (if first then 0 else 1))
      (.maximum (.input 0) (.input 1)))
  | .minNestedRight first => .value (.minimum (.input (if first then 0 else 1))
      (.minimum (.input 0) (.input 1)))
  | .maxMinClamp outer inner => .value
      (.maxOrder outer (.input 1) (.minOrder inner (.input 0) (.input 2)))
  | .minMaxClamp outer inner => .value
      (.minOrder outer (.input 2) (.maxOrder inner (.input 0) (.input 1)))
  | .maxClampLower reverse => .value
      (.maxOrder reverse (.input 1) (.clamp (.input 1) (.input 0) (.input 2)))
  | .compareSelf direction => .predicate (.compare direction (.input 0) (.input 0))
  | .compareZero .inputLtZero => .predicate (.compare .lt (.input 0) .zero)
  | .compareZero .zeroGtInput => .predicate (.compare .gt .zero (.input 0))
  | .compareZero .inputGeZero => .predicate (.compare .ge (.input 0) .zero)
  | .compareZero .zeroLeInput => .predicate (.compare .le .zero (.input 0))
  | .maxCompareFirst => .predicate (.compare .gt (.maximum (.input 0) (.input 1)) (.input 0))
  | .maxCompareSecond => .predicate (.compare .gt (.maximum (.input 0) (.input 1)) (.input 1))
  | .minCompareFirst => .predicate (.compare .gt (.input 0) (.minimum (.input 0) (.input 1)))
  | .minCompareSecond => .predicate (.compare .gt (.input 1) (.minimum (.input 0) (.input 1)))
  | .tautological first second => .predicate (.and
      (if first then .compare .gt (.input 1) (.input 0) else .compare .lt (.input 0) (.input 1))
      (if second then .compare .gt (.input 2) (.input 0) else .compare .lt (.input 0) (.input 2)))
  | .clampIdempotent => .value
      (.clamp (.input 1) (.clamp (.input 1) (.input 0) (.input 2)) (.input 2))
  | .clampRange => .value (.clamp .zero (.input 0) (.input 1))

/-- The actual replacement trees, retaining operand order when the retained replacement does. -/
def Rule.rhs : Rule → Graph
  | .maxSelf | .minSelf | .maxExtreme _ | .minExtreme _ | .clampRange => .value (.input 0)
  | .maxNestedLeft _ => .value (.maximum (.input 0) (.input 1))
  | .minNestedLeft _ => .value (.minimum (.input 0) (.input 1))
  | .maxNestedRight true => .value (.maximum (.input 0) (.input 1))
  | .maxNestedRight false => .value (.maximum (.input 1) (.input 0))
  | .minNestedRight true => .value (.minimum (.input 0) (.input 1))
  | .minNestedRight false => .value (.minimum (.input 1) (.input 0))
  | .maxMinClamp _ _ | .minMaxClamp _ _ | .maxClampLower _ | .clampIdempotent =>
      .value (.clamp (.input 1) (.input 0) (.input 2))
  | .compareSelf direction => .predicate (.constant (match direction with
      | .lt | .gt | .ne => false | .le | .ge | .eq => true))
  | .compareZero direction => .predicate (.constant (match direction with
      | .inputLtZero | .zeroGtInput => false | .inputGeZero | .zeroLeInput => true))
  | .maxCompareFirst | .minCompareSecond => .predicate (.compare .gt (.input 1) (.input 0))
  | .maxCompareSecond | .minCompareFirst => .predicate (.compare .gt (.input 0) (.input 1))
  | .tautological _ _ => .predicate (.compare .lt (.input 0) (.minimum (.input 1) (.input 2)))

/-- Independent pointwise mathematical domains; recognition/optimizer guards are not assumptions. -/
def Rule.Condition {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (rule : Rule) (inputs : Nat → Tensor shape α) : Prop :=
  match rule with
  | .maxExtreme _ => ∀ i, inputs 1 i ≤ inputs 0 i
  | .minExtreme _ => ∀ i, inputs 0 i ≤ inputs 1 i
  | .maxMinClamp _ _ | .maxClampLower _ => ∀ i, inputs 1 i ≤ inputs 2 i
  | .compareZero _ => ∀ i, 0 ≤ inputs 0 i
  | .clampRange => ∀ i, 0 ≤ inputs 0 i ∧ inputs 0 i ≤ inputs 1 i
  | _ => True

/-- Computable scalar admission check; its equivalence to the tensor condition is proved
separately. -/
def Rule.admittedAt {α : Type} [LinearOrder α] [Zero α]
    (rule : Rule) (values : Nat → α) : Bool :=
  match rule with
  | .maxExtreme _ => decide (values 1 ≤ values 0)
  | .minExtreme _ => decide (values 0 ≤ values 1)
  | .maxMinClamp _ _ | .maxClampLower _ => decide (values 1 ≤ values 2)
  | .compareZero _ => decide (0 ≤ values 0)
  | .clampRange => decide (0 ≤ values 0 ∧ values 0 ≤ values 1)
  | _ => true

/-- Stable unique names include every constructor parameter; no matched order is deduplicated. -/
def Rule.key : Rule → String
  | .maxSelf => "max_self" | .minSelf => "min_self"
  | .maxExtreme b => "max_extreme_" ++ if b then "1" else "0"
  | .minExtreme b => "min_extreme_" ++ if b then "1" else "0"
  | .maxNestedLeft b => "max_nested_left_" ++ if b then "1" else "0"
  | .minNestedLeft b => "min_nested_left_" ++ if b then "1" else "0"
  | .maxNestedRight b => "max_nested_right_" ++ if b then "1" else "0"
  | .minNestedRight b => "min_nested_right_" ++ if b then "1" else "0"
  | .maxMinClamp b c => "max_min_clamp_" ++
      (if b then "1" else "0") ++ (if c then "1" else "0")
  | .minMaxClamp b c => "min_max_clamp_" ++
      (if b then "1" else "0") ++ (if c then "1" else "0")
  | .maxClampLower b => "max_clamp_lower_" ++ if b then "1" else "0"
  | .compareSelf .lt => "compare_self_lt" | .compareSelf .le => "compare_self_le"
  | .compareSelf .gt => "compare_self_gt" | .compareSelf .ge => "compare_self_ge"
  | .compareSelf .eq => "compare_self_eq" | .compareSelf .ne => "compare_self_ne"
  | .compareZero .inputLtZero => "compare_zero_input_lt_zero"
  | .compareZero .zeroGtInput => "compare_zero_zero_gt_input"
  | .compareZero .inputGeZero => "compare_zero_input_ge_zero"
  | .compareZero .zeroLeInput => "compare_zero_zero_le_input"
  | .maxCompareFirst => "max_compare_first" | .maxCompareSecond => "max_compare_second"
  | .minCompareFirst => "min_compare_first" | .minCompareSecond => "min_compare_second"
  | .tautological b c => "tautological_" ++
      (if b then "1" else "0") ++ (if c then "1" else "0")
  | .clampIdempotent => "clamp_idempotent" | .clampRange => "clamp_range"

/-- Every admitted constructor/order instance, in a fixed computable enumeration. -/
def allRules : List Rule :=
  [.maxSelf,.minSelf] ++
  [false,true].flatMap (fun b => [.maxExtreme b,.minExtreme b,.maxNestedLeft b,.minNestedLeft b,
    .maxNestedRight b,.minNestedRight b,.maxClampLower b]) ++
  [false,true].flatMap (fun b => [false,true].flatMap (fun c =>
    [.maxMinClamp b c,.minMaxClamp b c,.tautological b c])) ++
  [.lt,.le,.gt,.ge,.eq,.ne].map Rule.compareSelf ++
  [.inputLtZero,.zeroGtInput,.inputGeZero,.zeroLeInput].map Rule.compareZero ++
  [.maxCompareFirst,.maxCompareSecond,.minCompareFirst,.minCompareSecond,
    .clampIdempotent,.clampRange]

end TensorRewrite.Theory.OrderFamily
