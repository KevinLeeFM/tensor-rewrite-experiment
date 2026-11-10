module

public import TensorRewrite.Pilot.Tensor

/-! The PRED constant-guard abstraction. Literal storage is finite; addressing and
each wrapper carry total bounded index maps. Exact C++ memory/attribute decoding
and the construction of those maps remain source-correspondence obligations. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ConstantGuard

/-- The seven operand-zero wrappers recognized by UnwrapToConstant. -/
inductive Wrapper where
  | broadcast
  | copy
  | dynamicSlice
  | reshape
  | reverse
  | slice
  | transpose
deriving Repr, DecidableEq

/-- Adjacent storage equality, corresponding to equal overlapping memory ranges. -/
def adjacentEqual : List Bool → Bool
  | [] | [_] => true
  | first :: second :: rest => (first == second) && adjacentEqual (second :: rest)

/-- Empty storage matchesAll; otherwise check its first value and adjacent equality. -/
def matchesAll (value : Bool) : List Bool → Bool
  | [] => true
  | first :: rest => (first == value) && adjacentEqual (first :: rest)

/-- Literal values with a bounded address for every logical tensor coordinate. -/
structure DenseLiteral {rank : Nat} (shape : Shape rank) where
  storage : List Bool
  address : Index shape → Fin storage.length

/-- Read a literal at a valid logical coordinate. -/
def DenseLiteral.eval {rank : Nat} {shape : Shape rank} (literal : DenseLiteral shape) :
    Tensor shape Bool := fun index => literal.storage[literal.address index]

/-- A constant leaf, recognized wrapper chain, or unrecognized operation value. -/
inductive View : (rank : Nat) → Shape rank → Type where
  | literal {rank : Nat} {shape : Shape rank} (value : DenseLiteral shape) : View rank shape
  | unrecognized {rank : Nat} {shape : Shape rank} (value : Tensor shape Bool) : View rank shape
  | reindex {inputRank outputRank : Nat} {inputShape : Shape inputRank}
      {outputShape : Shape outputRank} (kind : Wrapper) (operand : View inputRank inputShape)
      (indexMap : Index outputShape → Index inputShape) : View outputRank outputShape

/-- The independent logical value of a view, including unrecognized operations. -/
def View.eval : {rank : Nat} → {shape : Shape rank} → View rank shape → Tensor shape Bool
  | _, _, .literal value => value.eval
  | _, _, .unrecognized value => value
  | _, _, .reindex _ operand indexMap => fun index => operand.eval (indexMap index)

/-- Follow only recognized wrappers, then run the finite literal uniformity check. -/
def View.isAll (value : Bool) : {rank : Nat} → {shape : Shape rank} → View rank shape → Bool
  | _, _, .literal lit => matchesAll value lit.storage
  | _, _, .unrecognized _ => false
  | _, _, .reindex _ operand _ => operand.isAll value

end TensorRewrite.Pilot.ConstantGuard
