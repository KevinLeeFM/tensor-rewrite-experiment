module

public import TensorRewrite.Pilot.OperandOrder

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot

/-- A commutative operation removes the captured operand orientation. -/
theorem OperandOrder.map₂_eq {rank : Nat} {shape : Shape rank} {α : Type}
    (operation : α → α → α) (commutative : ∀ lhs rhs, operation lhs rhs = operation rhs lhs)
    (swapped : Bool) (lhs rhs : Tensor shape α) :
    map₂ operation swapped lhs rhs = Tensor.map₂ operation lhs rhs := by
  cases swapped with
  | false => rfl
  | true => funext index; exact commutative (rhs index) (lhs index)

/-- Pullback along one index map commutes with pointwise binary evaluation. -/
theorem Tensor.reindex_map₂ {smallRank rank : Nat} {smallShape : Shape smallRank}
    {shape : Shape rank} {α : Type} (indexMap : Index shape → Index smallShape)
    (operation : α → α → α) (lhs rhs : Tensor smallShape α) :
    reindex indexMap (map₂ operation lhs rhs) =
      map₂ operation (reindex indexMap lhs) (reindex indexMap rhs) := rfl

/-- Pullback of a uniform value stays uniform, including scalar and empty shapes. -/
theorem Tensor.reindex_constant {smallRank rank : Nat} {smallShape : Shape smallRank}
    {shape : Shape rank} {α : Type} (indexMap : Index shape → Index smallShape) (value : α) :
    reindex indexMap (constant value) = constant value := rfl

end TensorRewrite.Pilot
