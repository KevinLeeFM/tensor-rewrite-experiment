module

public import TensorRewrite.Pilot.SliceShape

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape.Exact

/-- The transformed axis retains the original static declaration exactly on
unit-stride or nonempty original axes. -/
def PreservesShapeExactly (transform : Int → Axis → Axis) : Prop :=
  ∀ (extent declared : Int) (axis : Axis), IsWellFormed extent declared axis →
    (IsWellFormed extent declared (transform extent axis) ↔
      axis.stride = 1 ∨ axis.start < axis.limit)

/-- The source axis update for redundant-stride removal has no need for the
input extent. -/
def RemoveRedundantStrideShape : Prop :=
  PreservesShapeExactly (fun _ axis => removeRedundantStride axis)

/-- Reverse reordering rewrites a single axis in the reverse mask. -/
def ReorderReverseShape : Prop :=
  PreservesShapeExactly reorderReverse

/-- Successful stride removal reads the same input coordinate at every
admitted output index. -/
def RemoveRedundantStrideCoordinate : Prop :=
  ∀ (extent declared : Int) (axis : Axis), IsWellFormed extent declared axis →
    (axis.stride = 1 ∨ axis.start < axis.limit) →
    ∀ j : Int, 0 ≤ j → j < declared →
      (removeRedundantStride axis).start + j * (removeRedundantStride axis).stride =
        axis.start + j * axis.stride

/-- Reverse after the transformed slice reads the same un-reversed input
coordinate as the original slice after reverse. -/
def ReorderReverseCoordinate : Prop :=
  ∀ (extent declared : Int) (axis : Axis), IsWellFormed extent declared axis →
    (axis.stride = 1 ∨ axis.start < axis.limit) →
    ∀ j : Int, 0 ≤ j → j < declared →
      (reorderReverse extent axis).start +
        (declared - 1 - j) * (reorderReverse extent axis).stride =
          extent - 1 - (axis.start + j * axis.stride)

end TensorRewrite.Pilot.SliceShape.Exact
