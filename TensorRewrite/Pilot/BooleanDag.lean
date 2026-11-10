module

public import TensorRewrite.Pilot.Dag
public import TensorRewrite.Pilot.Tensor

/-! Same-shape PRED operations for the pure DAG model. Wrong arity is rejected;
this is not an encoding of the C++ matcher, layouts, metadata or control edges. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.BooleanDag

/-- Boolean operation names; nullary constants make construction explicit. -/
inductive Opcode where
  | constant (value : Bool)
  | logicalNot
  | logicalAnd
  | logicalOr
  | logicalXor
deriving Repr, DecidableEq

/-- Exact arbitrary-rank Boolean tensor semantics with explicit arity rejection. -/
def meaning {rank : Nat} (shape : Shape rank) :
    Opcode → List (Tensor shape Bool) → Option (Tensor shape Bool)
  | .constant value, [] => some (Tensor.constant value)
  | .logicalNot, [x] => some (Tensor.map Bool.not x)
  | .logicalAnd, [lhs, rhs] => some (Tensor.map₂ Bool.and lhs rhs)
  | .logicalOr, [lhs, rhs] => some (Tensor.map₂ Bool.or lhs rhs)
  | .logicalXor, [lhs, rhs] => some (Tensor.map₂ Bool.xor lhs rhs)
  | _, _ => none

end TensorRewrite.Pilot.BooleanDag
