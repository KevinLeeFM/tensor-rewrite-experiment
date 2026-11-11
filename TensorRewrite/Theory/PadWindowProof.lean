module

public import TensorRewrite.Theory.PadWindowLemmas

/-! Order-preserving Pad fusion, with conversion and initializer boundaries made explicit. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PadWindow

open Pilot

/-- The complete optional sample map composes axiswise through the independent Pad. -/
theorem sample_compose {rank : Nat} (plan : Plan rank)
    (output : Index (outerWindow plan).outputShape)
    (kernel : Index (outerWindow plan).kernelShape) :
    (ReductionWindow.sample? (outerWindow plan) output kernel).bind (padIndex? plan) =
      ReductionWindow.sample? (fusedWindow plan) (outputIndex plan output) kernel := by
  trans LatticeIndex.assemble? (fun axis =>
    (((outerWindow plan).window axis).inputIndex? (output axis).val (kernel axis)).bind
      (plan.padding axis).sample?)
  · exact LatticeIndex.assemble_bind _ _
  · apply congrArg LatticeIndex.assemble?
    funext axis
    exact axis_compose (plan.padding axis) (plan.window axis) (output axis).val (kernel axis)

/-- Every contribution is preserved when explicit and implicit padding use the same value. -/
theorem contribution_fusion {rank : Nat} {α : Type} (plan : Plan rank) (fill : α)
    (input : Tensor plan.inputShape α) (output : Index (outerWindow plan).outputShape)
    (kernel : Index (outerWindow plan).kernelShape) :
    ReductionWindow.contribution (outerWindow plan) fill (pad plan fill input) output kernel =
      ReductionWindow.contribution (fusedWindow plan) fill input
        (outputIndex plan output) kernel := by
  unfold ReductionWindow.contribution
  rw [← sample_compose]
  cases ReductionWindow.sample? (outerWindow plan) output kernel with
  | none => rfl
  | some padded =>
    dsimp only [Option.bind, pad]
    cases padIndex? plan padded <;> rfl

/-- Fusion retains the exact ordered contribution list, including every padding position. -/
theorem values_fusion {rank : Nat} {α : Type} (plan : Plan rank) (fill : α)
    (input : Tensor plan.inputShape α) (output : Index (outerWindow plan).outputShape) :
    ReductionWindow.values (outerWindow plan) fill (pad plan fill input) output =
      ReductionWindow.values (fusedWindow plan) fill input (outputIndex plan output) := by
  unfold ReductionWindow.values
  apply List.map_congr_left
  intro position _
  exact contribution_fusion plan fill input output _

/-- Any pure reducer and its actual initializer are preserved by the derived fusion. -/
theorem reduce_fusion {rank : Nat} {α : Type} (plan : Plan rank) (operation : α → α → α)
    (initial fill : α) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce (outerWindow plan) operation initial fill (pad plan fill input) =
      fun output => ReductionWindow.reduce (fusedWindow plan) operation initial fill input
        (outputIndex plan output) := by
  funext output
  change (ReductionWindow.values _ _ _ _).foldl operation initial = _
  rw [values_fusion]
  rfl

/-- A pure scalar conversion commutes with Pad only with its actual converted fill value. -/
theorem map_pad {rank : Nat} {α β : Type} (plan : Plan rank) (convert : α → β) (fill : α)
    (input : Tensor plan.inputShape α) :
    Tensor.map convert (pad plan fill input) =
      pad plan (convert fill) (Tensor.map convert input) := by
  funext output
  unfold Tensor.map pad
  cases padIndex? plan output <;> rfl

/-- Convert/Pad/window fusion preserves the converted fill, without scalar homomorphism laws. -/
theorem convert_reduce_fusion {rank : Nat} {α β : Type} (plan : Plan rank) (convert : α → β)
    (operation : β → β → β) (initial : β) (fill : α) (input : Tensor plan.inputShape α) :
    ReductionWindow.reduce (outerWindow plan) operation initial (convert fill)
      (Tensor.map convert (pad plan fill input)) =
      fun output => ReductionWindow.reduce (fusedWindow plan) operation initial (convert fill)
        (Tensor.map convert input) (outputIndex plan output) := by
  calc
    _ = ReductionWindow.reduce (outerWindow plan) operation initial (convert fill)
        (pad plan (convert fill) (Tensor.map convert input)) :=
      congrArg (fun operand : Tensor plan.paddedShape β =>
        ReductionWindow.reduce (outerWindow plan) operation initial (convert fill) operand)
        (map_pad plan convert fill input)
    _ = _ := reduce_fusion plan operation initial (convert fill) (Tensor.map convert input)

/-- An explicitly checked converted-pad/initializer equality specializes the conversion theorem. -/
theorem convert_initial_fusion {rank : Nat} {α β : Type} (plan : Plan rank) (convert : α → β)
    (operation : β → β → β) (initial : β) (fill : α) (input : Tensor plan.inputShape α)
    (converted_fill : convert fill = initial) :
    ReductionWindow.reduce (outerWindow plan) operation initial initial
      (Tensor.map convert (pad plan fill input)) =
      fun output => ReductionWindow.reduce (fusedWindow plan) operation initial initial
        (Tensor.map convert input) (outputIndex plan output) := by
  rw [← converted_fill]
  exact convert_reduce_fusion _ _ _ _ _ _

end TensorRewrite.Theory.PadWindow
