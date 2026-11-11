module

public import TensorRewrite.Theory.PadBroadcastCompile

/-! The actual derived reshape/Broadcast graph with only proved shape transports. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

open Pilot

/-- Transport a real terminal sequence across equality of complete window attributes. -/
def sequenceAlong {α : Type} (target : BroadcastWindow.Plan)
    (window : ReductionWindow.Plan target.rank) (same : window = BroadcastWindow.windowPlan target)
    (input : Tensor window.inputShape α) : Tensor window.outputShape α := by
  cases same
  exact BroadcastWindow.sequence target input

/-- The composed target is logical Reshape/Broadcast, with derived output-bound transport. -/
def sequence {α : Type} (plan : Plan) (input : Tensor (padPlan plan).inputShape α) :
    Tensor (PadWindow.outerWindow (padPlan plan)).outputShape α := fun output =>
  sequenceAlong (broadcastPlan plan) (PadWindow.fusedWindow (padPlan plan)) (fused_window plan)
    input (PadWindow.outputIndex (padPlan plan) output)

end TensorRewrite.Theory.PadBroadcast
