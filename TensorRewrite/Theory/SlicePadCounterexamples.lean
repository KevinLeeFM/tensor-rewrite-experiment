module

public import TensorRewrite.Theory.SlicePadFactor

/-! Concrete geometry certificates distinguish derived starts and clipped padding. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.SlicePad

open Pilot

/-- A fractional-stride padding example used only by the certificates. -/
def fractionalPlan : ReductionWindow.Plan 1 := ⟨fun _ => {
  inputExtent := 5
  kernelExtent := 1
  stride := 2
  baseDilation := 1
  kernelDilation := 1
  paddingLow := 1
  paddingHigh := 0
  reversed := false
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide
}⟩

/-- A legal Slice whose rounded-down start is nevertheless the wrong transformation. -/
def wrongStart : Slice 1 where
  inputShape := fractionalPlan.inputShape
  outputShape := fun _ => 2
  axes := fun _ => ⟨0,3,2⟩
  valid := by decide +revert

/-- Output coordinate one observes the first actual input sample after the padded boundary. -/
def fractionalOutput : Index fractionalPlan.outputShape := fun _ => ⟨1, by decide +revert⟩

/-- Round-down start selection changes a value despite legal Slice attributes and equal shapes. -/
theorem rounded_start_refuted :
    let input : Tensor fractionalPlan.inputShape Nat := fun index => (index 0).val + 1
    graph fractionalPlan 0 id input fractionalOutput = 2 ∧
      ((⟨fun _ => 1, fun _ => 0⟩ : Padding 1).tensor 0 (wrongStart.tensor input)
        (fun _ => ⟨1, by decide +revert⟩)) = 1 ∧ (2 : Nat) ≠ 1 := by
  decide

/-- Failing to clip threshold padding changes output shape when every output precedes the input. -/
theorem unclipped_shape_refuted :
    let axis : Axis := ⟨1,2,2,7,by decide⟩
    axis.first = 2 ∧ axis.last = 2 ∧ axis.count = 0 ∧
      (ceilDiv axis.low axis.stride).toNat = 4 ∧
      axis.first + axis.count + (axis.outputExtent - axis.last) = 2 ∧
      (ceilDiv axis.low axis.stride).toNat + axis.count +
        (axis.outputExtent - (ceilDiv (axis.low + axis.inputExtent) axis.stride).toNat) = 4 ∧
      (2 : Nat) ≠ 4 := by
  decide

end TensorRewrite.Theory.SlicePad
