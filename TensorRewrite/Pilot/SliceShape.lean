module

public import Std

/-! One static slice axis and its declared output extent. Arithmetic uses
mathematical integers with truncation toward zero; machine overflow and graph
extraction are separate obligations. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape

/-- Start, exclusive limit and stride of one slice axis. Invalid bounds remain
representable so that output well-formedness can be an actual conclusion. -/
structure Axis where
  start : Int
  limit : Int
  stride : Int
deriving DecidableEq, Repr

/-- Number of output elements required by the static slice bounds. On valid
bounds this is the nonnegative ceiling of `(limit-start)/stride`. -/
def Axis.elementCount (axis : Axis) : Int :=
  (axis.limit - axis.start + axis.stride - 1).tdiv axis.stride

/-- A static slice axis has legal bounds and a declared output extent equal
to the count inferred from those bounds. -/
def IsWellFormed (extent declared : Int) (axis : Axis) : Prop :=
  0 ≤ axis.start ∧ axis.start ≤ axis.limit ∧ axis.limit ≤ extent ∧
    0 < axis.stride ∧ 0 ≤ declared ∧ axis.elementCount = declared

instance (extent declared : Int) (axis : Axis) : Decidable (IsWellFormed extent declared axis) := by
  unfold IsWellFormed
  infer_instance

/-- Bound transformation performed on a selected redundant-stride axis;
unselected axes are unchanged. -/
def removeRedundantStride (axis : Axis) : Axis :=
  if axis.stride ≠ 1 ∧
      (axis.stride ≥ axis.limit ∨ axis.start + axis.stride ≥ axis.limit) then
    { axis with limit := axis.start + 1, stride := 1 }
  else axis

/-- Bound transformation performed on one reversed slice axis. Truncating
division is necessary when the slice is empty and the numerator is negative. -/
def reorderReverse (extent : Int) (axis : Axis) : Axis :=
  let stepCount := (axis.limit - axis.start - 1).tdiv axis.stride
  let adjustedLimit := axis.start + stepCount * axis.stride + 1
  { axis with
    start := (extent - axis.start) - (adjustedLimit - axis.start)
    limit := extent - axis.start }

end TensorRewrite.Pilot.SliceShape
