module

public import TensorRewrite.Pilot.SliceShapeCore

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape

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
