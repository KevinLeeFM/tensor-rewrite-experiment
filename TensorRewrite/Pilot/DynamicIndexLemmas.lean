module

public import TensorRewrite.Pilot.DynamicIndex
public import TensorRewrite.Pilot.ConstantGuardLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- A full-extent slice starts at zero for every decoded start value. -/
theorem clampStart_full_extent (extent : Nat) (start : Int) :
    clampStart extent extent start = 0 := by
  unfold clampStart
  omega

/-- Signed and unsigned decoding agree when the finite word has no sign bit set. -/
theorem signedValue_eq_unsignedValue {width : Nat} (bits : BitVec width)
    (small : 2 * bits.toNat < 2 ^ width) : signedValue bits = unsignedValue bits :=
  BitVec.toInt_eq_toNat_of_lt small

/-- Concrete clamped index arithmetic has exactly the declared logical coordinate. -/
theorem dynamicSliceIndex_val {rank : Nat} {inputShape outputShape : Shape rank}
    (starts : Fin rank → Int) (fits : ∀ axis, outputShape axis ≤ inputShape axis)
    (index : Index outputShape) (axis : Fin rank) :
    ((dynamicSliceIndex starts fits index axis).val : Int) =
      clampStart (inputShape axis) (outputShape axis) (starts axis) + (index axis : Int) := by
  apply Int.toNat_of_nonneg
  exact (coordinate_bounds (inputShape axis) (outputShape axis) (fits axis) (starts axis)
    (index axis) (by omega) (by have h := (index axis).isLt; omega)).1

/-- Constant recognition is sound with the actual clamped logical map. -/
theorem dynamicSliceView_constant {rank : Nat} {inputShape outputShape : Shape rank}
    (operand : ConstantGuard.View rank inputShape) (starts : Fin rank → Int)
    (fits : ∀ axis, outputShape axis ≤ inputShape axis) (value : Bool)
    (guard : operand.isAll value = true) :
    (dynamicSliceView operand starts fits).eval = Tensor.constant value :=
  (dynamicSliceView operand starts fits).isAll_sound value guard

end TensorRewrite.Pilot.DynamicIndex
