module

public import TensorRewrite.Theory.PadBroadcastTarget

/-! Derived window equality transports actual terminal graph laws without new premises. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadBroadcast

open Pilot

/-- A complete attribute equality transfers the terminal reduction/graph proof. -/
theorem reduce_sequenceAlong {α : Type} (target : BroadcastWindow.Plan)
    (window : ReductionWindow.Plan target.rank) (same : window = BroadcastWindow.windowPlan target)
    (operation : α → α → α) (initial : α)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value) (input : Tensor window.inputShape α) :
    ReductionWindow.reduce window operation initial initial input =
      sequenceAlong target window same input := by
  cases same
  exact BroadcastWindow.reduce_sequence target operation initial left right input

/-- Pure scalar conversion commutes with the actual graph under derived attribute transport. -/
theorem sequenceAlong_map {α β : Type} (target : BroadcastWindow.Plan)
    (window : ReductionWindow.Plan target.rank) (same : window = BroadcastWindow.windowPlan target)
    (convert : α → β) (input : Tensor window.inputShape α) :
    sequenceAlong target window same (Tensor.map convert input) =
      Tensor.map convert (sequenceAlong target window same input) := by
  cases same
  exact BroadcastWindow.sequence_map target convert input

end TensorRewrite.Theory.PadBroadcast
