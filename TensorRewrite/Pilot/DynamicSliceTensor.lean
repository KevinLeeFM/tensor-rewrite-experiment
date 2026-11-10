module

public import TensorRewrite.Pilot.DynamicIndex

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- Logical DynamicSlice values from the concrete bounded coordinate map. -/
def sliceTensor {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (input : Tensor inputShape α) (starts : Fin rank → Int)
    (fits : ∀ axis, outputShape axis ≤ inputShape axis) : Tensor outputShape α :=
  fun index => input (dynamicSliceIndex starts fits index)

/-- Add the independently clamped inner and outer starts of a nested slice. -/
def combinedStart (extent intermediate width : Nat) (inner outer : Int) : Int :=
  clampStart extent intermediate inner + clampStart intermediate width outer

end TensorRewrite.Pilot.DynamicIndex
