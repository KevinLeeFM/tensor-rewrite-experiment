module

public import TensorRewrite.Theory.PadBroadcastLemmas

/-! Compose independent Pad fusion with derived logical Reshape/Broadcast graph equality. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

open Pilot

/-- The independent Pad/window graph equals its derived sequence under two identity laws. -/
theorem reduce_sequence {α : Type} (plan : Plan) (operation : α → α → α) (initial : α)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value)
    (input : Tensor (padPlan plan).inputShape α) :
    ReductionWindow.reduce (PadWindow.outerWindow (padPlan plan)) operation initial initial
      (PadWindow.pad (padPlan plan) initial input) = sequence plan input := by
  rw [PadWindow.reduce_fusion]
  funext output
  exact congrFun (reduce_sequenceAlong (broadcastPlan plan) _ (fused_window plan)
    operation initial left right input) (PadWindow.outputIndex (padPlan plan) output)

/-- Pure conversion commutes with the entire constructed target graph. -/
theorem sequence_map {α β : Type} (plan : Plan) (convert : α → β)
    (input : Tensor (padPlan plan).inputShape α) :
    sequence plan (Tensor.map convert input) = Tensor.map convert (sequence plan input) := by
  funext output
  exact congrFun (sequenceAlong_map (broadcastPlan plan) _ (fused_window plan) convert input)
    (PadWindow.outputIndex (padPlan plan) output)

/-- Conversion may move after the target only with its actual fill mapped to the initializer. -/
theorem reduce_converted_sequence {α β : Type} (plan : Plan) (convert : α → β)
    (operation : β → β → β) (initial : β) (fill : α)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value)
    (convertedFill : convert fill = initial) (input : Tensor (padPlan plan).inputShape α) :
    ReductionWindow.reduce (PadWindow.outerWindow (padPlan plan)) operation initial initial
      (Tensor.map convert (PadWindow.pad (padPlan plan) fill input)) =
      Tensor.map convert (sequence plan input) := by
  calc
    _ = ReductionWindow.reduce (PadWindow.outerWindow (padPlan plan)) operation initial initial
        (PadWindow.pad (padPlan plan) (convert fill) (Tensor.map convert input)) :=
      congrArg (fun operand : Tensor (padPlan plan).paddedShape β =>
        ReductionWindow.reduce (PadWindow.outerWindow (padPlan plan)) operation initial initial
          operand) (PadWindow.map_pad (padPlan plan) convert fill input)
    _ = sequence plan (Tensor.map convert input) := by
      rw [convertedFill]
      exact reduce_sequence plan operation initial left right (Tensor.map convert input)
    _ = _ := sequence_map plan convert input

end TensorRewrite.Theory.PadBroadcast
