module

public import TensorRewrite.Theory.ArithmeticBroadcast

/-! Paper-era Broadcast laws for actual bounded coordinate projections. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Broadcast

open Pilot Theory.ArithmeticFamily

/-- `broadcast/rule01`: addition commutes with a shared Broadcast. -/
theorem add {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (left right : Tensor smallShape α) :
    Tensor.map₂ (· + ·) (Tensor.reindex (IndexMaps.broadcastIndex axes extents) left)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) right) =
      Tensor.reindex (IndexMaps.broadcastIndex axes extents) (Tensor.map₂ (· + ·) left right) := rfl

/-- `broadcast/rule02`: multiplication commutes with a shared Broadcast. -/
theorem multiply {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (left right : Tensor smallShape α) :
    Tensor.map₂ (· * ·) (Tensor.reindex (IndexMaps.broadcastIndex axes extents) left)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) right) =
      Tensor.reindex (IndexMaps.broadcastIndex axes extents) (Tensor.map₂ (· * ·) left right) := rfl

/-- `broadcast/rule04`: reversing any axes leaves a uniform tensor unchanged. -/
theorem reverse_constant {α : Type} {rank : Nat} {shape : Shape rank}
    (axes : Fin rank → Bool) (value : α) :
    Tensor.reverse axes (Tensor.constant value : Tensor shape α) = Tensor.constant value := rfl

/-- `mul/rule07`: move a uniform scalar factor inside the actual Broadcast. -/
theorem uniform_factor {α : Type} [CommRing α] {smallRank rank : Nat}
    {smallShape : Shape smallRank} {shape : Shape rank}
    (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis))
    (input : Tensor shape α) (small : Tensor smallShape α) (factor : α) :
    Tensor.map₂ (· * ·) (Tensor.map₂ (· * ·) input (Tensor.constant factor))
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents) small) =
      Tensor.map₂ (· * ·)
        (Tensor.reindex (IndexMaps.broadcastIndex axes extents)
          (Tensor.map₂ (· * ·) small (Tensor.constant factor))) input := by
  have existing := broadcast_uniform_factor axes extents false false input small factor
  simp only [OperandOrder.map₂] at existing
  rw [existing]
  funext index
  exact mul_comm _ _

#print axioms add
#print axioms multiply
#print axioms reverse_constant
#print axioms uniform_factor

end TensorRewrite.PaperComparison.Broadcast
