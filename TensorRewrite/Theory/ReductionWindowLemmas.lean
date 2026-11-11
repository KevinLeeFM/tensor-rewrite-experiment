module

public import TensorRewrite.Theory.ReductionWindow
public import TensorRewrite.Theory.ConvolutionLemmas
public import TensorRewrite.Theory.ConvolutionPointwiseLemmas
public import TensorRewrite.Theory.ConvolutionOrderedLemmas

/-! Window geometry and ordered sample-list facts, independent of scalar algebra. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionWindow

open Pilot Convolution

/-- The sample list includes one value for every bounded window position. -/
theorem values_length {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    (values plan padding input output).length = LinearIndex.elementCount plan.kernelShape := by
  simp [values]

/-- An empty input has no bounded sample, even when padding creates nonempty output. -/
theorem sample_empty_input {rank : Nat} (plan : Plan rank)
    (empty : LinearIndex.elementCount plan.inputShape = 0)
    (output : Index plan.outputShape) (kernel : Index plan.kernelShape) :
    sample? plan output kernel = none :=
  spatialInput?_empty plan.asConvolution empty output kernel

/-- Every position in a window over empty input still contributes the supplied padding value. -/
theorem values_empty_input {rank : Nat} {α : Type} (plan : Plan rank) (padding : α)
    (input : Tensor plan.inputShape α) (empty : LinearIndex.elementCount plan.inputShape = 0)
    (output : Index plan.outputShape) :
    values plan padding input output =
      List.replicate (LinearIndex.elementCount plan.kernelShape) padding := by
  unfold values contribution
  simp only [sample_empty_input plan empty]
  rw [List.map_const', List.length_finRange]

/-- A unit window has one coordinate, including at rank zero. -/
theorem unit_count {rank : Nat} (plan : Plan rank) (unit : IsUnit plan) :
    LinearIndex.elementCount plan.kernelShape = 1 :=
  ConvolutionPointwise.elementCount_unit plan.kernelShape unit

/-- The unit window's canonical coordinate is its only coordinate. -/
theorem unit_index_unique {rank : Nat} (plan : Plan rank) (unit : IsUnit plan)
    (index : Index plan.kernelShape) : index = unitIndex plan unit :=
  ConvolutionPointwise.kernel_index_unique plan.asConvolution unit index

/-- Unit windows enumerate one actual contribution without using any fold law. -/
theorem values_unit {rank : Nat} {α : Type} (plan : Plan rank) (unit : IsUnit plan)
    (padding : α) (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    values plan padding input output =
      [contribution plan padding input output (unitIndex plan unit)] := by
  unfold values
  rw [ConvolutionOrdered.map_finRange_singleton (unit_count plan unit)]
  exact congrArg (fun kernel => [contribution plan padding input output kernel])
    (unit_index_unique plan unit _)

/-- A unit window has no kernel offset, including reversed and kernel-dilated windows. -/
theorem axis_unit_position (axis : Axis) (unit : axis.kernelExtent = 1)
    (output : Nat) (kernel : Fin axis.kernelExtent) :
    axis.basePosition output kernel = (output : Int) * axis.stride - axis.paddingLow := by
  have value : kernel.val = 0 := by have := kernel.isLt; omega
  cases reversed : axis.reversed <;>
    simp [Axis.basePosition, reversed, value, unit]

/-- Undilated unit-window sampling is a signed bounded affine coordinate check. -/
theorem axis_unit_sample (axis : Axis) (unit : axis.kernelExtent = 1)
    (undilated : axis.baseDilation = 1) (output : Nat) (kernel : Fin axis.kernelExtent) :
    axis.inputIndex? output kernel =
      boundedIndex? axis.inputExtent ((output : Int) * axis.stride - axis.paddingLow) := by
  simp [Axis.inputIndex?, axis_unit_position axis unit, undilated, boundedIndex?]

/-- The whole unit-window sampler equals the independently defined affine crop/stride gather. -/
theorem sample_unit_affine {rank : Nat} (plan : Plan rank) (unit : IsUnit plan)
    (undilated : IsUndilated plan) (output : Index plan.outputShape)
    (kernel : Index plan.kernelShape) : sample? plan output kernel = affineInput? plan output := by
  unfold sample? Convolution.spatialInput? affineInput?
  have samples (axis : Fin rank) :=
    axis_unit_sample (plan.window axis) (unit axis) (undilated axis)
      (output axis).val (kernel axis)
  simp only [Plan.asConvolution, affinePosition] at *
  simp only [samples]
  rfl

/-- Repeating a value leaves a fixed accumulator unchanged, without a nonempty-list premise. -/
theorem foldl_replicate_fixed {α : Type} (operation : α → α → α) (initial padding : α)
    (fixed : operation initial padding = initial) (count : Nat) :
    (List.replicate count padding).foldl operation initial = initial := by
  induction count with
  | zero => rfl
  | succ count ih => rw [List.replicate_succ, List.foldl_cons, fixed, ih]

/-- Signed positions outside an axis never produce a bounded coordinate. -/
theorem bounded_none_of_outside (extent : Nat) (position : Int)
    (outside : position < 0 ∨ (extent : Int) ≤ position) :
    boundedIndex? extent position = none := by
  have invalid : ¬ (0 ≤ position ∧ position < (extent : Int)) := by omega
  simp [boundedIndex?, invalid]

/-- One invalid affine axis suffices to make the whole crop/stride gather invalid. -/
theorem affine_none_of_axis {rank : Nat} (plan : Plan rank) (output : Index plan.outputShape)
    (axis : Fin rank) (outside : affinePosition plan output axis < 0 ∨
      ((plan.window axis).inputExtent : Int) ≤ affinePosition plan output axis) :
    affineInput? plan output = none := by
  have invalid : ¬ ∀ axis,
      (boundedIndex? ((plan.window axis).inputExtent)
        (affinePosition plan output axis)).isSome := by
    intro valid
    have admitted := valid axis
    rw [bounded_none_of_outside _ _ outside] at admitted
    contradiction
  simp [affineInput?, invalid]

end TensorRewrite.Theory.ReductionWindow
