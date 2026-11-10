import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Tensor

namespace ModularControls

/-- Native probe shape; general theorems are not restricted to it. -/
def shape : Shape 1 := fun _ => 6

/-- The eight expressions compared with the native evaluator. -/
inductive Rule where
  | addZero | addConstant | addAssoc | factor | mulZero | mulOne | mulNegNeg | fourFactors
  deriving Repr

/-- Stable evidence protocol names. -/
def Rule.tag : Rule → String
  | .addZero => "add_zero"
  | .addConstant => "add_constant"
  | .addAssoc => "add_assoc"
  | .factor => "factor"
  | .mulZero => "mul_zero"
  | .mulOne => "mul_one"
  | .mulNegNeg => "mul_neg_neg"
  | .fourFactors => "four_factors"

/-- Nonuniform values at zero, one and modular boundaries. -/
def left (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 0 | 1 => 1 | 2 => 2^width-1 | 3 => 2^(width-1) | 4 => 2^width-2 | _ => 3)

/-- A second independent value vector. -/
def right (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 2^width-1 | 1 => 2 | 2 => 3 | 3 => 2^(width-1) | 4 => 4 | _ => 2^width-1)

/-- A nonconstant shared factor. -/
def shared (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 2^width-1 | 1 => 1 | 2 => 2 | 3 => 3 | 4 => 2^(width-1) | _ => 2^width-2)

/-- Original modular tensor expressions. -/
def before (width : Nat) : Rule → Tensor shape (BitVec width)
  | .addZero => map₂ (· + ·) (left width) (constant 0)
  | .addConstant => map₂ (· + ·) (constant 2) (left width)
  | .addAssoc => map₂ (· + ·) (map₂ (· + ·) (left width) (constant 2)) (constant 3)
  | .factor => map₂ (· + ·) (map₂ (· * ·) (left width) (shared width))
      (map₂ (· * ·) (right width) (shared width))
  | .mulZero => map₂ (· * ·) (left width) (constant 0)
  | .mulOne => map₂ (· * ·) (left width) (constant 1)
  | .mulNegNeg => map₂ (· * ·) (map Neg.neg (left width)) (map Neg.neg (right width))
  | .fourFactors => map₂ (· * ·) (map₂ (· * ·) (left width) (constant 2))
      (map₂ (· * ·) (right width) (constant 3))

/-- Replacement modular tensor expressions. -/
def after (width : Nat) : Rule → Tensor shape (BitVec width)
  | .addZero => left width
  | .addConstant => map₂ (· + ·) (left width) (constant 2)
  | .addAssoc => map₂ (· + ·) (left width) (map₂ (· + ·) (constant 2) (constant 3))
  | .factor => map₂ (· * ·) (map₂ (· + ·) (left width) (right width)) (shared width)
  | .mulZero => constant 0
  | .mulOne => left width
  | .mulNegNeg => map₂ (· * ·) (left width) (right width)
  | .fourFactors => map₂ (· * ·) (map₂ (· * ·) (left width) (right width))
      (map₂ (· * ·) (constant 2) (constant 3))

/-- Decode every cell as a natural representative of its word. -/
def observe {width : Nat} (tensor : Tensor shape (BitVec width)) : List Nat :=
  List.ofFn (fun cell : Fin 6 => (tensor (fun _ => cell)).toNat)

#eval show IO Unit from do
  for width in [8, 32, 64] do
    for rule in [Rule.addZero, .addConstant, .addAssoc, .factor, .mulZero, .mulOne,
        .mulNegNeg, .fourFactors] do
      let original := observe (before width rule)
      let rewritten := observe (after width rule)
      unless original == rewritten do throw (IO.userError "modular probe disagreement")
      IO.println ("MODULAR_MODEL width=" ++ toString width ++ " case=" ++ rule.tag ++
        " values=" ++ String.intercalate "," (rewritten.map toString))

end ModularControls
