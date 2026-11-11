module

public import TensorRewrite.Theory.UnitAxisLemmas
public import TensorRewrite.Pilot.Indexing

/-! Ordinary Reshape and signed-axis Broadcast for deleting then expanding one singleton. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.UnitAxis

open Pilot

/-- Delete the singleton by logical Reshape, then Broadcast at the constructed retained axes. -/
def sequence {rank : Nat} {α : Type} (plan : Plan rank) (copies : Nat)
    (input : Tensor plan.inputShape α) : Tensor (plan.targetShape copies) α :=
  Tensor.reindex (IndexMaps.broadcastIndex plan.broadcastAxes (fun axis => by
    rw [axes_decode]
    exact axes_extent plan copies axis))
    (Reshape.reshapeTensor input plan.outputShape (count plan))

end TensorRewrite.Theory.UnitAxis
