module

public import TensorRewrite.Theory.ConvolutionSeparable

/-! Derive mixed-window shape relations and bounded sampling from convolution geometry. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionSeparable

open Pilot Convolution ConvolutionPointwise

/-- Without dilation, padding or stride, output extent is the truncated input-minus-kernel size. -/
theorem output_extent_formula (axis : Axis) (separable : IsSeparableAxis axis) :
    axis.outputExtent = ((axis.inputExtent : Int) - axis.kernelExtent + 1).toNat := by
  simp only [Axis.outputExtent, separable.unitStride, separable.unitBaseDilation,
    separable.unitKernelDilation, separable.noLowPadding, separable.noHighPadding,
    dilatedExtent_one]
  simp

/-- One output window implies equal input/kernel extents, including empty kernels. -/
theorem spanning_extent_eq (axis : Axis) (separable : IsSeparableAxis axis)
    (singleOutput : axis.outputExtent = 1) : axis.kernelExtent = axis.inputExtent := by
  rw [output_extent_formula axis separable] at singleOutput
  omega

/-- The dependent coordinate geometry follows from the actual window conditions. -/
theorem derive_geometry {rank : Nat} (plan : Plan rank) (separable : IsSeparable plan) :
    Geometry plan := {
  unit := by
    intro axis unit
    exact output_extent_eq (plan.window axis)
      ⟨unit, (separable axis).unitStride, (separable axis).unitBaseDilation,
        (separable axis).noLowPadding, (separable axis).noHighPadding⟩
  spanning := by
    intro axis notUnit
    have singleOutput : (plan.window axis).outputExtent = 1 :=
      (separable axis).degenerate.resolve_left notUnit
    exact ⟨singleOutput, spanning_extent_eq (plan.window axis) (separable axis) singleOutput⟩
}

/-- Sampling uses the output coordinate on a unit-kernel axis and a reversed kernel coordinate
on a spanning axis. The boundedness premise is derived from shape geometry. -/
theorem axis_inputIndex_eq (axis : Axis) (separable : IsSeparableAxis axis)
    (output : Fin axis.outputExtent) (kernel : Fin axis.kernelExtent) :
    axis.inputIndex? output.val kernel = some (if unit : axis.kernelExtent = 1 then
      Fin.cast (output_extent_eq axis ⟨unit, separable.unitStride, separable.unitBaseDilation,
        separable.noLowPadding, separable.noHighPadding⟩) output
      else Fin.cast (spanning_extent_eq axis separable (separable.degenerate.resolve_left unit))
        (if axis.reversed then kernel.rev else kernel)) := by
  by_cases unit : axis.kernelExtent = 1
  · simp only [dite_eq_left unit]
    exact ConvolutionPointwise.axis_inputIndex_eq axis
      ⟨unit, separable.unitStride, separable.unitBaseDilation,
        separable.noLowPadding, separable.noHighPadding⟩ output kernel
  · have singleOutput := separable.degenerate.resolve_left unit
    have outputZero : output.val = 0 := by have := output.isLt; omega
    have extent := spanning_extent_eq axis separable singleOutput
    have bound : (if axis.reversed then kernel.rev else kernel).val < axis.inputExtent := by
      rw [← extent]
      exact (if axis.reversed then kernel.rev else kernel).isLt
    simp only [dite_eq_right unit]
    cases reversed : axis.reversed <;>
      simp [Axis.inputIndex?, Axis.basePosition, outputZero, separable.unitBaseDilation,
        separable.unitKernelDilation, separable.noLowPadding, reversed, Fin.ext_iff] <;>
      simpa [reversed] using bound

/-- Mixed-window sampling never takes the padding/dilation-hole branch at a valid coordinate. -/
theorem spatial_input_eq {rank : Nat} (plan : Plan rank) (separable : IsSeparable plan)
    (output : Index plan.outputShape) (kernel : Index plan.kernelShape) :
    spatialInput? plan output kernel = some
      (productInputIndex plan (derive_geometry plan separable) output
        (reverseKernel plan kernel)) := by
  have samples (axis : Fin rank) :=
    axis_inputIndex_eq (plan.window axis) (separable axis) (output axis) (kernel axis)
  have valid : ∀ axis,
      ((plan.window axis).inputIndex? (output axis).val (kernel axis)).isSome := by
    intro axis
    rw [samples axis]
    rfl
  unfold spatialInput?
  rw [dite_eq_left valid]
  congr 1
  funext axis
  simp only [samples, Option.get_some, productInputIndex, reverseKernel]
  split <;> apply Fin.ext <;> rfl

end TensorRewrite.Theory.ConvolutionSeparable
