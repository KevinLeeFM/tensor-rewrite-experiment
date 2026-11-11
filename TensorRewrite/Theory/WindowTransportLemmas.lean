module

public import TensorRewrite.Theory.WindowTransport
public import TensorRewrite.Theory.ReductionFiberLemmas

/-! State transport preserves every contribution and the actual fold schedule. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTransport

open Pilot

/-- Mapping a contribution maps valid input and the actual invalid-sample value alike. -/
theorem contribution_map {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank)
    (map : α → β) (padding : α) (input : Tensor plan.inputShape α)
    (output : Index plan.outputShape) (kernel : Index plan.kernelShape) :
    ReductionWindow.contribution plan (map padding) (Tensor.map map input) output kernel =
      map (ReductionWindow.contribution plan padding input output kernel) := by
  unfold ReductionWindow.contribution
  cases ReductionWindow.sample? plan output kernel <;> rfl

/-- Pure value maps preserve the order and multiplicity of the complete window sample list. -/
theorem values_map {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank) (map : α → β)
    (padding : α) (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    ReductionWindow.values plan (map padding) (Tensor.map map input) output =
      (ReductionWindow.values plan padding input output).map map := by
  unfold ReductionWindow.values
  rw [List.map_map]
  apply List.map_congr_left
  intro position _
  exact contribution_map plan map padding input output _

/-- Moving a map through the fold requires preservation of operation, initializer and padding. -/
theorem reduce_map {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank) (map : α → β)
    (source : α → α → α) (target : β → β → β)
    (hom : ∀ first second, target (map first) (map second) = map (source first second))
    (initial padding : α) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan target (map initial) (map padding) (Tensor.map map input) =
      Tensor.map map (ReductionWindow.reduce plan source initial padding input) := by
  funext output
  change (ReductionWindow.values _ _ _ _).foldl target (map initial) = _
  rw [values_map]
  exact ReductionFiber.foldl_map_hom map source target hom _ initial

/-- An invertible state representation transports any pure reducer without algebraic laws. -/
theorem reduce_equiv {rank : Nat} {α β : Type} (plan : ReductionWindow.Plan rank)
    (equivalence : α ≃ β) (source : α → α → α) (initial padding : α)
    (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce plan (operation equivalence source) (equivalence initial)
      (equivalence padding) (Tensor.map equivalence input) =
      Tensor.map equivalence (ReductionWindow.reduce plan source initial padding input) := by
  apply reduce_map
  intro first second
  simp [operation]

end TensorRewrite.Theory.WindowTransport
