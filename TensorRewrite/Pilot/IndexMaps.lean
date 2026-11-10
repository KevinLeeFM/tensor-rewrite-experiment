module

public import TensorRewrite.Pilot.ConstantGuard
public import TensorRewrite.Pilot.SliceIndexBounds

/-! Concrete bounded logical maps for static HLO Broadcast and Slice.
Signed attributes use mathematical Int; C++ decoding, overflow, physical layout
and unbounded dynamic dimensions remain separate source obligations. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.IndexMaps

/-- A signed Broadcast dimension array with its exact length and range checked. -/
structure BroadcastAxes (inputRank outputRank : Nat) where
  values : Vector Int inputRank
  valid : ∀ axis : Fin inputRank, 0 ≤ values[axis] ∧ values[axis] < (outputRank : Int)
deriving Repr

/-- Decode a checked signed axis without silently clipping a negative value. -/
def BroadcastAxes.decode {inputRank outputRank : Nat} (axes : BroadcastAxes inputRank outputRank)
    (axis : Fin inputRank) : Fin outputRank :=
  ⟨axes.values[axis].toNat, (Int.toNat_lt (axes.valid axis).1).mpr (axes.valid axis).2⟩

/-- Project an output coordinate onto the exactly matching HLO operand axes. -/
def broadcastIndex {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (axes : BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis))
    (index : Index outputShape) : Index inputShape :=
  fun axis => Fin.cast (extents axis).symm (index (axes.decode axis))

/-- Compute start+stride*index on each static Slice axis and prove the input bound. -/
def sliceIndex {rank : Nat} {inputShape outputShape : Shape rank}
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis))
    (index : Index outputShape) : Index inputShape := fun axis =>
  let coordinate := (axes axis).start + (axes axis).stride * (index axis : Int)
  have bound := SliceShape.coordinate_bounds (valid axis) (index axis) (by omega)
    (by have h := (index axis).isLt; omega)
  ⟨coordinate.toNat, (Int.toNat_lt bound.1).mpr bound.2⟩

/-- Construct a recognized Broadcast view from actual axis attributes and extent equalities. -/
def broadcastView {inputRank outputRank : Nat} {inputShape : Shape inputRank}
    {outputShape : Shape outputRank} (operand : ConstantGuard.View inputRank inputShape)
    (axes : BroadcastAxes inputRank outputRank)
    (extents : ∀ axis, inputShape axis = outputShape (axes.decode axis)) :
    ConstantGuard.View outputRank outputShape :=
  .reindex .broadcast operand (broadcastIndex axes extents)

/-- Construct a recognized Slice view from the checked static start/limit/stride arrays. -/
def sliceView {rank : Nat} {inputShape outputShape : Shape rank}
    (operand : ConstantGuard.View rank inputShape) (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (inputShape axis) (outputShape axis) (axes axis)) :
    ConstantGuard.View rank outputShape := .reindex .slice operand (sliceIndex axes valid)

end TensorRewrite.Pilot.IndexMaps
