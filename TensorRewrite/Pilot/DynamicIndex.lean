module

public import TensorRewrite.Pilot.ConstantGuard
public import TensorRewrite.Pilot.DynamicIndexBounds

/-! Concrete DynamicSlice maps on static bounded shapes. Starts are decoded
mathematical values; unsigned evaluator conversion is tracked separately. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- Concrete arbitrary-rank bounded DynamicSlice coordinate map. -/
def dynamicSliceIndex {rank : Nat} {inputShape outputShape : Shape rank}
    (starts : Fin rank → Int) (fits : ∀ axis, outputShape axis ≤ inputShape axis)
    (index : Index outputShape) : Index inputShape := fun axis =>
  let coordinate := clampStart (inputShape axis) (outputShape axis) (starts axis) +
    (index axis : Int)
  have bound := coordinate_bounds (inputShape axis) (outputShape axis) (fits axis)
    (starts axis) (index axis) (by omega) (by have h := (index axis).isLt; omega)
  ⟨coordinate.toNat, (Int.toNat_lt bound.1).mpr bound.2⟩

/-- Build the recognized DynamicSlice view from concrete starts and valid sizes. -/
def dynamicSliceView {rank : Nat} {inputShape outputShape : Shape rank}
    (operand : ConstantGuard.View rank inputShape) (starts : Fin rank → Int)
    (fits : ∀ axis, outputShape axis ≤ inputShape axis) :
    ConstantGuard.View rank outputShape :=
  .reindex .dynamicSlice operand (dynamicSliceIndex starts fits)

end TensorRewrite.Pilot.DynamicIndex
