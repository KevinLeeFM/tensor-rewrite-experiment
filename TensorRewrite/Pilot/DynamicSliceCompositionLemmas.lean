module

public import TensorRewrite.Pilot.DynamicSliceTensor
public import TensorRewrite.Pilot.DynamicIndexLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- Combined clamped starts fit the outer slice's source extent. -/
theorem combinedStart_bounds (extent intermediate width : Nat)
    (innerFits : intermediate ≤ extent) (outerFits : width ≤ intermediate)
    (inner outer : Int) :
    0 ≤ combinedStart extent intermediate width inner outer ∧
      combinedStart extent intermediate width inner outer ≤ (extent : Int) - width := by
  have innerBound := clampStart_bounds extent intermediate innerFits inner
  have outerBound := clampStart_bounds intermediate width outerFits outer
  unfold combinedStart
  constructor <;> omega

/-- Reclamping the combined start does not alter it. -/
theorem clampStart_combined (extent intermediate width : Nat)
    (innerFits : intermediate ≤ extent) (outerFits : width ≤ intermediate)
    (inner outer : Int) :
    clampStart extent width (combinedStart extent intermediate width inner outer) =
      combinedStart extent intermediate width inner outer := by
  have bound := combinedStart_bounds extent intermediate width innerFits outerFits inner outer
  unfold clampStart
  omega

/-- Nested concrete index maps equal the single map with combined starts. -/
theorem dynamicSliceIndex_compose {rank : Nat} {inputShape middleShape outputShape : Shape rank}
    (inner outer : Fin rank → Int)
    (innerFits : ∀ axis, middleShape axis ≤ inputShape axis)
    (outerFits : ∀ axis, outputShape axis ≤ middleShape axis) (index : Index outputShape) :
    dynamicSliceIndex inner innerFits (dynamicSliceIndex outer outerFits index) =
      dynamicSliceIndex (fun axis => combinedStart (inputShape axis) (middleShape axis)
        (outputShape axis) (inner axis) (outer axis))
        (fun axis => Nat.le_trans (outerFits axis) (innerFits axis)) index := by
  funext axis
  apply Fin.ext
  have left := dynamicSliceIndex_val inner innerFits
    (dynamicSliceIndex outer outerFits index) axis
  have middle := dynamicSliceIndex_val outer outerFits index axis
  have right := dynamicSliceIndex_val
    (fun axis => combinedStart (inputShape axis) (middleShape axis)
      (outputShape axis) (inner axis) (outer axis))
    (fun axis => Nat.le_trans (outerFits axis) (innerFits axis)) index axis
  rw [clampStart_combined _ _ _ (innerFits axis) (outerFits axis)] at right
  have expand : combinedStart (inputShape axis) (middleShape axis) (outputShape axis)
      (inner axis) (outer axis) = clampStart (inputShape axis) (middleShape axis) (inner axis) +
        clampStart (middleShape axis) (outputShape axis) (outer axis) := rfl
  omega

end TensorRewrite.Pilot.DynamicIndex
