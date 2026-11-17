module
public import TensorRewrite.Theory.Concatenation

/-! One slice transported to a separately selected concatenation frame.
This module does not construct a list of blocks or prove a tensor rewrite. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.SliceTransport
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation

/-- Use the slice shape as the fixed extents of a new frame. -/
def destinationFrame {rank : Nat} (source : Frame rank) (length : Nat)
    (axis : Fin rank) : Frame rank :=
  ⟨source.shape length, axis⟩

/-- The destination frame at its original axis extent has precisely the slice shape. -/
theorem destination_shape {rank : Nat} (source : Frame rank) (length : Nat)
    (axis : Fin rank) :
    (destinationFrame source length axis).shape (source.shape length axis) =
      source.shape length := by
  funext i
  by_cases h : i = axis <;> simp [destinationFrame, Frame.shape, h]

/-- Cast each coordinate using the derived shape equality, without changing its value. -/
def destinationIndex {rank : Nat} (source : Frame rank) (length : Nat)
    (axis : Fin rank)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis))) :
    Index (source.shape length) :=
  fun i => Fin.cast (congrFun (destination_shape source length axis) i) (index i)

/-- Put one actual source-frame slice into a block for the destination frame. -/
def sliceBlock {rank extent : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (start length : Nat)
    (fits : start + length ≤ extent) (axis : Fin rank) :
    Block (destinationFrame source length axis) α :=
  ⟨source.shape length axis, fun index =>
    source.slice input start length fits (destinationIndex source length axis index)⟩

/-- Reframing preserves every coordinate value, including on unrelated zero extents. -/
theorem destinationIndex_value {rank : Nat} (source : Frame rank) (length : Nat)
    (axis : Fin rank)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis)))
    (i : Fin rank) : (destinationIndex source length axis index i).val = (index i).val := by
  rfl

/-- A distinct destination axis keeps its original extent after slicing. -/
theorem destination_extent_of_distinct {rank : Nat} (source : Frame rank)
    (length extent : Nat) (axis : Fin rank) (different : axis ≠ source.axis) :
    source.shape length axis = source.shape extent axis := by
  simp [Frame.shape, different]

/-- The block reads the existing slice at the transported index. -/
theorem sliceBlock_read {rank extent : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (start length : Nat)
    (fits : start + length ≤ extent) (axis : Fin rank)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis))) :
    (sliceBlock source input start length fits axis).values index =
      source.slice input start length fits (destinationIndex source length axis index) := rfl

#print axioms destination_shape
#print axioms destinationIndex_value
#print axioms destination_extent_of_distinct
#print axioms sliceBlock_read
end Heldout.SliceTransport
