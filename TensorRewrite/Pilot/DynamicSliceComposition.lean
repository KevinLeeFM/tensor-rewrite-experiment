module

public import TensorRewrite.Pilot.DynamicSliceCompositionLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- Arbitrary-rank nested logical DynamicSlice preserves every element value. -/
theorem sliceTensor_compose {rank : Nat} {inputShape middleShape outputShape : Shape rank}
    {α : Type} (input : Tensor inputShape α) (inner outer : Fin rank → Int)
    (innerFits : ∀ axis, middleShape axis ≤ inputShape axis)
    (outerFits : ∀ axis, outputShape axis ≤ middleShape axis) :
    sliceTensor (sliceTensor input inner innerFits) outer outerFits =
      sliceTensor input (fun axis => combinedStart (inputShape axis) (middleShape axis)
        (outputShape axis) (inner axis) (outer axis))
        (fun axis => Nat.le_trans (outerFits axis) (innerFits axis)) := by
  funext index
  exact congrArg input (dynamicSliceIndex_compose inner outer innerFits outerFits index)

end TensorRewrite.Pilot.DynamicIndex
