module

public import TensorRewrite.Pilot.DynamicIndexValue

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- Clamping a valid slice size always produces a bounded, nonnegative start. -/
theorem clampStart_bounds (extent width : Nat) (fits : width ≤ extent) (start : Int) :
    0 ≤ clampStart extent width start ∧
      clampStart extent width start ≤ (extent : Int) - (width : Int) := by
  unfold clampStart
  omega

/-- An output coordinate added to the clamped start remains in the input extent. -/
theorem coordinate_bounds (extent width : Nat) (fits : width ≤ extent) (start index : Int)
    (nonnegative : 0 ≤ index) (bounded : index < (width : Int)) :
    0 ≤ clampStart extent width start + index ∧
      clampStart extent width start + index < (extent : Int) := by
  have bound := clampStart_bounds extent width fits start
  constructor <;> omega

end TensorRewrite.Pilot.DynamicIndex
