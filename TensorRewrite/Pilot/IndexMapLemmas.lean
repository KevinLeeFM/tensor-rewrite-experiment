module

public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.ConstantGuardLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.IndexMaps

/-- The projection uses the decoded source dimension, with no coordinate modification. -/
theorem broadcastIndex_val {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (axes : BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (index : Index outputShape) (axis : Fin inputRank) :
    (broadcastIndex axes extents index axis).val = (index (axes.decode axis)).val := by
  rfl

/-- Slice coordinate arithmetic agrees exactly with its signed start/stride formula. -/
theorem sliceIndex_val {rank : Nat} {inputShape outputShape : Shape rank}
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis))
    (index : Index outputShape) (axis : Fin rank) :
    ((sliceIndex axes valid index axis).val : Int) =
      (axes axis).start + (axes axis).stride * (index axis : Int) := by
  apply Int.toNat_of_nonneg
  exact (SliceShape.coordinate_bounds (valid axis) (index axis) (by omega)
    (by have h := (index axis).isLt; omega)).1

/-- The guard now has a concrete Broadcast map rather than a supplied map parameter. -/
theorem broadcastView_constant {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (operand : ConstantGuard.View inputRank inputShape)
    (axes : BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis)) (value : Bool)
    (guard : operand.isAll value = true) :
    (broadcastView operand axes extents).eval = Tensor.constant value :=
  (broadcastView operand axes extents).isAll_sound value guard

/-- Legal static Slice attributes likewise determine the bounded guard-preserving map. -/
theorem sliceView_constant {rank : Nat} {inputShape outputShape : Shape rank}
    (operand : ConstantGuard.View rank inputShape) (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis))
    (value : Bool) (guard : operand.isAll value = true) :
    (sliceView operand axes valid).eval = Tensor.constant value :=
  (sliceView operand axes valid).isAll_sound value guard

end TensorRewrite.Pilot.IndexMaps
