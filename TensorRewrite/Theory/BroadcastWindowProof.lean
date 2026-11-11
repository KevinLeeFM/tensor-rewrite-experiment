module

public import TensorRewrite.Theory.BroadcastWindowFold
public import TensorRewrite.Theory.BroadcastWindowIndex

/-! Covered singleton windows are an actual reshape-plus-Broadcast under explicit identities. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- A covered window with one live contribution returns its source value under two identity laws. -/
theorem reduce_source {α : Type} (plan : Plan) (operation : α → α → α) (initial : α)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value)
    (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial initial input =
      fun output => input (sourceIndex plan output) := by
  funext output
  change ((List.finRange _).map _).foldl operation initial = _
  have values : ReductionWindow.values (windowPlan plan) initial input output =
      (List.finRange (LinearIndex.elementCount (windowPlan plan).kernelShape)).map
        (fun position => if position = livePosition plan output then
          input (sourceIndex plan output) else initial) := by
    apply List.map_congr_left
    intro position _
    exact contribution_at_position plan initial input output position
  change (ReductionWindow.values (windowPlan plan) initial input output).foldl operation initial = _
  rw [values]
  exact foldl_single_live operation initial initial _ (left _) right _ (livePosition plan output)

/-- The actual window equals the constructed logical reshape and signed-axis Broadcast graph. -/
theorem reduce_sequence {α : Type} (plan : Plan) (operation : α → α → α) (initial : α)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value)
    (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial initial input =
      sequence plan input := by
  rw [reduce_source plan operation initial left right]
  funext output
  exact (sequence_value plan input output).symm

/-- Pure conversion commutes with the derived reshape/Broadcast sequence, without a fold law. -/
theorem sequence_map {α β : Type} (plan : Plan) (convert : α → β)
    (input : Tensor (windowPlan plan).inputShape α) :
    sequence plan (Tensor.map convert input) = Tensor.map convert (sequence plan input) := by
  funext output
  rw [sequence_value]
  change convert (input (sourceIndex plan output)) = convert (sequence plan input output)
  rw [sequence_value]

/-- Input conversion moves after the Broadcast sequence under both result-reducer identities. -/
theorem reduce_converted_sequence {α β : Type} (plan : Plan) (convert : α → β)
    (operation : β → β → β) (initial : β)
    (left : ∀ value, operation initial value = value)
    (right : ∀ value, operation value initial = value)
    (input : Tensor (windowPlan plan).inputShape α) :
    ReductionWindow.reduce (windowPlan plan) operation initial initial (Tensor.map convert input) =
      Tensor.map convert (sequence plan input) := by
  rw [reduce_sequence plan operation initial left right, sequence_map]

end TensorRewrite.Theory.BroadcastWindow
