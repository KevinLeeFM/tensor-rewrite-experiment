module

public import TensorRewrite.Pilot.Indexing

/-! Explicit operand orientation for commutative source matcher alternatives.
The flag records a captured order; this does not implement the C++ matcher. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.OperandOrder

/-- Apply a pointwise binary operation in the selected original operand order. -/
def map₂ {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α) :
    Bool → Tensor shape α → Tensor shape α → Tensor shape α
  | false, lhs, rhs => Tensor.map₂ operation lhs rhs
  | true, lhs, rhs => Tensor.map₂ operation rhs lhs

end TensorRewrite.Pilot.OperandOrder
