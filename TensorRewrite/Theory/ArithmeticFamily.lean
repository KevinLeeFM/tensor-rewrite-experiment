module

public import TensorRewrite.Pilot.Indexing
public import TensorRewrite.Pilot.IndexMaps
public import Mathlib.Data.BitVec
public import Mathlib.Tactic.DeriveFintype
public import Mathlib.Data.Fintype.Sum
public import Mathlib.Data.Fintype.Prod
public import Mathlib.Data.Fintype.Sigma

/-! A closed pure arithmetic rewrite vocabulary with explicit operations and matched orders. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ArithmeticFamily

open Pilot

/-- Scalar meanings are explicit; ring laws are required by the soundness theorem, not this
expression evaluator. Rounded operations can interpret the same syntax separately. -/
structure Operations (α : Type) where
  zero : α
  one : α
  add : α → α → α
  sub : α → α → α
  mul : α → α → α
  neg : α → α

/-- Exact mathematical operations supplied by a commutative ring, including modular words. -/
def Operations.exact (α : Type) [CommRing α] : Operations α :=
  ⟨0, 1, (· + ·), (· - ·), (· * ·), (- ·)⟩

/-- Shape-preserving arithmetic/selection expressions over arbitrary shared tensor inputs. -/
inductive Expr where
  | input (number : Nat)
  | zero
  | one
  | ofPredicate (number : Nat)
  | neg (operand : Expr)
  | add (left right : Expr)
  | sub (left right : Expr)
  | mul (left right : Expr)
  | select (predicate : Nat) (yes no : Expr)
deriving Repr

/-- Evaluate the actual tree and its chosen scalar operations at every bounded tensor index. -/
def Expr.eval {α : Type} {rank : Nat} {shape : Shape rank} (ops : Operations α)
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Expr → Tensor shape α
  | .input number => inputs number
  | .zero => Tensor.constant ops.zero
  | .one => Tensor.constant ops.one
  | .ofPredicate number => fun index => if predicates number index then ops.one else ops.zero
  | .neg operand => Tensor.map ops.neg (operand.eval ops inputs predicates)
  | .add left right => Tensor.map₂ ops.add (left.eval ops inputs predicates)
      (right.eval ops inputs predicates)
  | .sub left right => Tensor.map₂ ops.sub (left.eval ops inputs predicates)
      (right.eval ops inputs predicates)
  | .mul left right => Tensor.map₂ ops.mul (left.eval ops inputs predicates)
      (right.eval ops inputs predicates)
  | .select predicate yes no => fun index => if predicates predicate index then
      yes.eval ops inputs predicates index else no.eval ops inputs predicates index

/-- Retain the actual matched left/right sum order in the expression tree. -/
def Expr.addOrder (reverse : Bool) (left right : Expr) : Expr :=
  if reverse then .add right left else .add left right

/-- Retain the actual matched left/right product order in the expression tree. -/
def Expr.mulOrder (reverse : Bool) (left right : Expr) : Expr :=
  if reverse then .mul right left else .mul left right

/-- Closed scalar-value identities; Boolean fields enumerate every admitted matcher order. -/
inductive Rule where
  | negNeg | addZeroLeft | addZeroRight | addComm
  | addCancelLeft | addCancelRight | subSelf | subZero | subNeg | subSubSame
  | subAddSameLeft | subAddSameRight | addSubSameLeft | addSubSameRight
  | mulOneLeft | mulOneRight | mulZeroLeft | mulZeroRight | mulNegBoth
  | addAssoc (innerReverse outerReverse : Bool)
  | subAddConstants (outerReverse : Bool)
  | mulAssoc (innerReverse outerReverse : Bool)
  | fourFactors (outerReverse leftReverse rightReverse : Bool)
  | factor (leftReverse rightReverse : Bool)
  | predicateMultiply (reverse : Bool)
deriving DecidableEq, Repr, Fintype

/-- Original expression with all operand positions and repeated inputs explicit. -/
def Rule.lhs : Rule → Expr
  | .negNeg => .neg (.neg (.input 0))
  | .addZeroLeft => .add .zero (.input 0)
  | .addZeroRight => .add (.input 0) .zero
  | .addComm => .add (.input 0) (.input 1)
  | .addAssoc inner outer => Expr.addOrder outer
      (Expr.addOrder inner (.input 0) (.input 1)) (.input 2)
  | .subAddConstants outer => Expr.addOrder outer (.sub (.input 0) (.input 1)) (.input 2)
  | .addCancelLeft => .add (.sub (.input 1) (.input 0)) (.input 0)
  | .addCancelRight => .add (.input 0) (.sub (.input 1) (.input 0))
  | .subSelf => .sub (.input 0) (.input 0)
  | .subZero => .sub (.input 0) .zero
  | .subNeg => .sub (.input 0) (.input 1)
  | .subSubSame => .sub (.input 0) (.sub (.input 0) (.input 1))
  | .subAddSameLeft => .sub (.input 0) (.add (.input 0) (.input 1))
  | .subAddSameRight => .sub (.input 0) (.add (.input 1) (.input 0))
  | .addSubSameLeft => .sub (.add (.input 0) (.input 1)) (.input 0)
  | .addSubSameRight => .sub (.add (.input 1) (.input 0)) (.input 0)
  | .mulOneLeft => .mul .one (.input 0)
  | .mulOneRight => .mul (.input 0) .one
  | .mulZeroLeft => .mul .zero (.input 0)
  | .mulZeroRight => .mul (.input 0) .zero
  | .mulNegBoth => .mul (.neg (.input 0)) (.neg (.input 1))
  | .mulAssoc inner outer => Expr.mulOrder outer
      (Expr.mulOrder inner (.input 0) (.input 1)) (.input 2)
  | .fourFactors outer left right => Expr.mulOrder outer
      (Expr.mulOrder left (.input 0) (.input 2)) (Expr.mulOrder right (.input 1) (.input 3))
  | .factor left right => .add (Expr.mulOrder left (.input 0) (.input 2))
      (Expr.mulOrder right (.input 1) (.input 2))
  | .predicateMultiply reverse => Expr.mulOrder reverse (.ofPredicate 0) (.input 0)

/-- Replacement expression in the same mathematical scalar/observation profile. -/
def Rule.rhs : Rule → Expr
  | .negNeg | .addZeroLeft | .addZeroRight | .subZero | .mulOneLeft | .mulOneRight => .input 0
  | .addComm => .add (.input 1) (.input 0)
  | .addAssoc _ _ => .add (.input 0) (.add (.input 1) (.input 2))
  | .subAddConstants _ => .sub (.add (.input 0) (.input 2)) (.input 1)
  | .addCancelLeft | .addCancelRight | .subSubSame | .addSubSameLeft | .addSubSameRight => .input 1
  | .subSelf | .mulZeroLeft | .mulZeroRight => .zero
  | .subNeg => .add (.input 0) (.neg (.input 1))
  | .subAddSameLeft | .subAddSameRight => .neg (.input 1)
  | .mulNegBoth => .mul (.input 0) (.input 1)
  | .mulAssoc _ _ => .mul (.input 0) (.mul (.input 1) (.input 2))
  | .fourFactors _ _ _ => .mul (.mul (.input 0) (.input 1)) (.mul (.input 2) (.input 3))
  | .factor _ _ => .mul (.add (.input 0) (.input 1)) (.input 2)
  | .predicateMultiply _ => .select 0 (.input 0) .zero

/-- A stable reporting key retaining every matcher-order bit. -/
def Rule.key : Rule → String
  | .negNeg => "neg_neg" | .addZeroLeft => "add_zero_left" | .addZeroRight => "add_zero_right"
  | .addComm => "add_comm"
  | .addCancelLeft => "add_cancel_left" | .addCancelRight => "add_cancel_right"
  | .subSelf => "sub_self" | .subZero => "sub_zero" | .subNeg => "sub_neg"
  | .subSubSame => "sub_sub_same" | .subAddSameLeft => "sub_add_same_left"
  | .subAddSameRight => "sub_add_same_right" | .addSubSameLeft => "add_sub_same_left"
  | .addSubSameRight => "add_sub_same_right" | .mulOneLeft => "mul_one_left"
  | .mulOneRight => "mul_one_right" | .mulZeroLeft => "mul_zero_left"
  | .mulZeroRight => "mul_zero_right" | .mulNegBoth => "mul_neg_both"
  | .addAssoc inner outer => "add_assoc_" ++
      (if inner then "1" else "0") ++ (if outer then "1" else "0")
  | .subAddConstants outer => "sub_add_constants_" ++ (if outer then "1" else "0")
  | .mulAssoc inner outer => "mul_assoc_" ++
      (if inner then "1" else "0") ++ (if outer then "1" else "0")
  | .fourFactors outer left right => "four_factors_" ++ (if outer then "1" else "0") ++
      (if left then "1" else "0") ++ (if right then "1" else "0")
  | .factor left right => "factor_" ++ (if left then "1" else "0") ++ (if right then "1" else "0")
  | .predicateMultiply reverse => "predicate_multiply_" ++ (if reverse then "1" else "0")

/-- Complete computable enumeration of the nineteen fixed and twenty-four order-specific rules. -/
def allRules : List Rule :=
  [.negNeg, .addZeroLeft, .addZeroRight, .addComm,
    .addCancelLeft, .addCancelRight, .subSelf, .subZero, .subNeg, .subSubSame,
    .subAddSameLeft, .subAddSameRight, .addSubSameLeft, .addSubSameRight,
    .mulOneLeft, .mulOneRight, .mulZeroLeft, .mulZeroRight, .mulNegBoth] ++
  [false, true].flatMap (fun inner => [false, true].map (Rule.addAssoc inner)) ++
  [false, true].map Rule.subAddConstants ++
  [false, true].flatMap (fun inner => [false, true].map (Rule.mulAssoc inner)) ++
  [false, true].flatMap (fun outer => [false, true].flatMap fun left =>
    [false, true].map (Rule.fourFactors outer left)) ++
  [false, true].flatMap (fun left => [false, true].map (Rule.factor left)) ++
  [false, true].map Rule.predicateMultiply

end TensorRewrite.Theory.ArithmeticFamily
