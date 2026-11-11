module

public import TensorRewrite.Pilot.Tensor

/-! A closed, typed family of pure Boolean/bitvector value identities.
True-constant identities are predicate-only; zero identities and involution also
support arbitrary-width words. Graph scheduling and code correspondence are separate. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.LogicalFamily

open Pilot

/-- Scalar domains on which the logical family is defined. -/
inductive Domain where
  | predicate
  | word (width : Nat)
deriving DecidableEq, Repr

/-- Mathematical values of a selected logical domain. -/
abbrev Domain.Value : Domain → Type
  | .predicate => Bool
  | .word width => BitVec width

instance (domain : Domain) : Repr domain.Value := by
  cases domain <;> infer_instance

/-- The additive/bitwise zero value in either logical domain. -/
def Domain.zero : (domain : Domain) → domain.Value
  | .predicate => false
  | .word width => 0#width

/-- Scalar logical negation, distinct from arithmetic sign negation. -/
def Domain.not : (domain : Domain) → domain.Value → domain.Value
  | .predicate => Bool.not
  | .word _ => fun value => ~~~value

/-- Scalar conjunction in the selected domain. -/
def Domain.and : (domain : Domain) → domain.Value → domain.Value → domain.Value
  | .predicate => Bool.and
  | .word _ => fun lhs rhs => lhs &&& rhs

/-- Scalar disjunction in the selected domain. -/
def Domain.or : (domain : Domain) → domain.Value → domain.Value → domain.Value
  | .predicate => Bool.or
  | .word _ => fun lhs rhs => lhs ||| rhs

/-- Scalar exclusive-or in the selected domain. -/
def Domain.xor : (domain : Domain) → domain.Value → domain.Value → domain.Value
  | .predicate => Bool.xor
  | .word _ => fun lhs rhs => lhs ^^^ rhs

/-- Shape-preserving logical tensor expressions with arbitrary shared input values. -/
inductive Expr (domain : Domain) where
  | input (number : Nat)
  | constant (value : domain.Value)
  | not (operand : Expr domain)
  | and (lhs rhs : Expr domain)
  | or (lhs rhs : Expr domain)
  | xor (lhs rhs : Expr domain)
deriving Repr

/-- Interpret expressions over arbitrary finite tensor shapes. -/
def Expr.eval {domain : Domain} {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape domain.Value) : Expr domain → Tensor shape domain.Value
  | .input number => inputs number
  | .constant value => Tensor.constant value
  | .not operand => Tensor.map domain.not (operand.eval inputs)
  | .and lhs rhs => Tensor.map₂ domain.and (lhs.eval inputs) (rhs.eval inputs)
  | .or lhs rhs => Tensor.map₂ domain.or (lhs.eval inputs) (rhs.eval inputs)
  | .xor lhs rhs => Tensor.map₂ domain.xor (lhs.eval inputs) (rhs.eval inputs)

/-- Closed rule vocabulary. Predicate-only constructors prevent accidental word-one identities. -/
inductive Rule : Domain → Type where
  | notNot {domain : Domain} : Rule domain
  | andZeroLeft {domain : Domain} : Rule domain
  | andZeroRight {domain : Domain} : Rule domain
  | orZeroLeft {domain : Domain} : Rule domain
  | orZeroRight {domain : Domain} : Rule domain
  | xorZeroLeft {domain : Domain} : Rule domain
  | xorZeroRight {domain : Domain} : Rule domain
  | xorEqual {domain : Domain} : Rule domain
  | andTrueLeft : Rule .predicate
  | andTrueRight : Rule .predicate
  | orTrueLeft : Rule .predicate
  | orTrueRight : Rule .predicate
deriving DecidableEq, Repr

/-- Stable identifiers for mathematical obligation reporting. -/
def Rule.key {domain : Domain} : Rule domain → String
  | .notNot => "not_not"
  | .andZeroLeft => "and_zero_left"
  | .andZeroRight => "and_zero_right"
  | .orZeroLeft => "or_zero_left"
  | .orZeroRight => "or_zero_right"
  | .xorZeroLeft => "xor_zero_left"
  | .xorZeroRight => "xor_zero_right"
  | .xorEqual => "xor_equal"
  | .andTrueLeft => "and_true_left"
  | .andTrueRight => "and_true_right"
  | .orTrueLeft => "or_true_left"
  | .orTrueRight => "or_true_right"

/-- Original expression of a logical identity. -/
def Rule.lhs {domain : Domain} : Rule domain → Expr domain
  | .notNot => .not (.not (.input 0))
  | .andZeroLeft => .and (.constant domain.zero) (.input 0)
  | .andZeroRight => .and (.input 0) (.constant domain.zero)
  | .orZeroLeft => .or (.constant domain.zero) (.input 0)
  | .orZeroRight => .or (.input 0) (.constant domain.zero)
  | .xorZeroLeft => .xor (.constant domain.zero) (.input 0)
  | .xorZeroRight => .xor (.input 0) (.constant domain.zero)
  | .xorEqual => .xor (.input 0) (.input 1)
  | .andTrueLeft => .and (.constant true) (.input 0)
  | .andTrueRight => .and (.input 0) (.constant true)
  | .orTrueLeft => .or (.constant true) (.input 0)
  | .orTrueRight => .or (.input 0) (.constant true)

/-- Replacement expression, including the actual selected constant value. -/
def Rule.rhs {domain : Domain} : Rule domain → Expr domain
  | .andZeroLeft | .andZeroRight | .xorEqual => .constant domain.zero
  | .orTrueLeft | .orTrueRight => .constant true
  | _ => .input 0

/-- Equal-input xor needs value equality; the remaining identities have no side condition. -/
def Rule.Condition {domain : Domain} {rank : Nat} {shape : Shape rank}
    (rule : Rule domain) (inputs : Nat → Tensor shape domain.Value) : Prop :=
  match rule with
  | .xorEqual => inputs 0 = inputs 1
  | _ => True

/-- Enumerate every admitted identity at a selected domain. -/
def allRules : (domain : Domain) → List (Rule domain)
  | .predicate => [.notNot, .andZeroLeft, .andZeroRight, .orZeroLeft, .orZeroRight,
      .xorZeroLeft, .xorZeroRight, .xorEqual, .andTrueLeft, .andTrueRight,
      .orTrueLeft, .orTrueRight]
  | .word _ => [.notNot, .andZeroLeft, .andZeroRight, .orZeroLeft, .orZeroRight,
      .xorZeroLeft, .xorZeroRight, .xorEqual]

end TensorRewrite.Theory.LogicalFamily
