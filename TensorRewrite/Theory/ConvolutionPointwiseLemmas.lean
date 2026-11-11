module

public import TensorRewrite.Theory.ConvolutionPointwise

/-! Shape and sampling facts derived from explicit pointwise window conditions. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionPointwise

open Pilot Convolution

/-- Dilation by one preserves empty and nonempty extents. -/
theorem dilatedExtent_one (extent : Nat) : dilatedExtent extent 1 = extent := by
  unfold dilatedExtent
  split <;> omega

/-- A pointwise window preserves its input extent, including the empty case. -/
theorem output_extent_eq (axis : Axis) (pointwise : IsPointwiseAxis axis) :
    axis.outputExtent = axis.inputExtent := by
  unfold Axis.outputExtent
  rw [pointwise.unitKernel, pointwise.unitStride, pointwise.unitBaseDilation,
    pointwise.noLowPadding, pointwise.noHighPadding, dilatedExtent_one]
  simp [dilatedExtent]

/-- The spatial output and input shapes coincide on every axis. -/
theorem output_shape_eq {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan) :
    plan.outputShape = plan.inputShape := by
  funext axis
  exact output_extent_eq (plan.window axis) (pointwise axis)

/-- A shape whose extents are all one has exactly one coordinate, also at rank zero. -/
theorem elementCount_unit {rank : Nat} (shape : Shape rank) (unit : ∀ axis, shape axis = 1) :
    LinearIndex.elementCount shape = 1 := by
  induction rank with
  | zero => rfl
  | succ rank ih =>
    simp only [LinearIndex.elementCount]
    rw [unit, ih _ (fun axis => unit axis.succ), Nat.one_mul]

/-- Pointwise convolution has a single spatial kernel coordinate. -/
theorem kernel_count_eq_one {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan) :
    LinearIndex.elementCount plan.kernelShape = 1 :=
  elementCount_unit plan.kernelShape (fun axis => (pointwise axis).unitKernel)

/-- All bounded kernel coordinates equal the canonical unit-kernel coordinate. -/
theorem kernel_index_unique {rank : Nat} (plan : Plan rank)
    (unitKernel : ∀ axis, plan.kernelShape axis = 1) (index : Index plan.kernelShape) :
    index = kernelIndex plan unitKernel := by
  funext axis
  apply Fin.ext
  have bound := (index axis).isLt
  have unit := unitKernel axis
  change (index axis).val = 0
  omega

/-- Unit kernels have no spatial offset even when reversed or kernel-dilated. -/
theorem base_position_eq (axis : Axis) (pointwise : IsPointwiseAxis axis)
    (output : Nat) (kernel : Fin axis.kernelExtent) :
    axis.basePosition output kernel = output := by
  have unit := pointwise.unitKernel
  have value : kernel.val = 0 := by have := kernel.isLt; omega
  simp [Axis.basePosition, pointwise.unitStride, pointwise.noLowPadding, unit, value]

/-- Sampling a pointwise window returns its bounded output coordinate as an input coordinate. -/
theorem axis_inputIndex_eq (axis : Axis) (pointwise : IsPointwiseAxis axis)
    (output : Fin axis.outputExtent) (kernel : Fin axis.kernelExtent) :
    axis.inputIndex? output.val kernel =
      some (Fin.cast (output_extent_eq axis pointwise) output) := by
  have bound : output.val < axis.inputExtent := by
    rw [← output_extent_eq axis pointwise]
    exact output.isLt
  simp [Axis.inputIndex?, base_position_eq axis pointwise, pointwise.unitBaseDilation,
    bound, Fin.ext_iff]

/-- All axes sample successfully and assemble precisely the shape-transported input index. -/
theorem spatial_input_eq {rank : Nat} (plan : Plan rank) (pointwise : IsPointwise plan)
    (output : Index plan.outputShape) (kernel : Index plan.kernelShape) :
    spatialInput? plan output kernel =
      some (inputIndex plan (output_shape_eq plan pointwise) output) := by
  unfold spatialInput?
  have samples (axis : Fin rank) :=
    axis_inputIndex_eq (plan.window axis) (pointwise axis) (output axis) (kernel axis)
  have valid : ∀ axis,
      ((plan.window axis).inputIndex? (output axis).val (kernel axis)).isSome := by
    intro axis
    rw [samples axis]
    rfl
  rw [dite_eq_left valid]
  congr 1
  funext axis
  dsimp only [inputIndex]
  simp only [samples, Option.get_some]
  apply Fin.ext
  rfl

end TensorRewrite.Theory.ConvolutionPointwise
