module

public import TensorRewrite.Pilot.SliceShape

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape

/-- Every declared static-slice output coordinate selects an in-bounds input coordinate. -/
theorem coordinate_bounds {extent declared : Int} {axis : Axis}
    (valid : IsWellFormed extent declared axis) (index : Int)
    (nonnegative : 0 ≤ index) (bounded : index < declared) :
    0 ≤ axis.start + axis.stride * index ∧
      axis.start + axis.stride * index < extent := by
  rcases valid with ⟨start_nonnegative, ordered, limit_bounded, positive, _, count⟩
  have numerator_nonnegative : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by omega
  have product_bound : axis.stride * declared ≤ axis.limit - axis.start + axis.stride - 1 := by
    rw [← count]
    exact Int.mul_tdiv_self_le numerator_nonnegative
  have step_bound : axis.stride * (index + 1) ≤ axis.stride * declared :=
    Int.mul_le_mul_of_nonneg_left (by omega) (by omega)
  rw [Int.mul_add, Int.mul_one] at step_bound
  have product_nonnegative : 0 ≤ axis.stride * index :=
    Int.mul_nonneg (by omega) nonnegative
  constructor <;> omega

end TensorRewrite.Pilot.SliceShape
