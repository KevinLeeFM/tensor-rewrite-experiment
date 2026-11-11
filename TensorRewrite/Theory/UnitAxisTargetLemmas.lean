module

public import TensorRewrite.Theory.UnitAxisTarget

/-! The actual operator sequence reads precisely the derived original tensor coordinate. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.UnitAxis

open Pilot

/-- The actual Reshape/Broadcast composition uses the proved projection and singleton insertion. -/
theorem sequence_value {rank : Nat} {α : Type} (plan : Plan rank) (copies : Nat)
    (input : Tensor plan.inputShape α) (index : Index (plan.targetShape copies)) :
    sequence plan copies input index = input (plan.insertIndex (plan.projectIndex index)) := by
  unfold sequence Tensor.reindex Reshape.reshapeTensor
  rw [broadcast_index, reshape_index]

end TensorRewrite.Theory.UnitAxis
