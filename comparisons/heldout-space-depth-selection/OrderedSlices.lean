module
public import SliceTransport
public import TensorRewrite.Theory.ConcatenationLemmas

/-! Ordered blocks of equally sized, individually legal slices. This is generic
concatenation support and does not state the reshape/transpose rewrite. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.OrderedSlices
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SliceTransport

/-- One legal unit-stride interval of a common extent and length. -/
structure Interval (extent length : Nat) where
  start : Nat
  fits : start + length ≤ extent

/-- Construct slices in exactly the provided list order. -/
def blocks {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis : Fin rank)
    (intervals : List (Interval extent length)) :
    List (Block (destinationFrame source length axis) α) :=
  intervals.map fun interval => sliceBlock source input interval.start length interval.fits axis

/-- Ordered equal-width blocks have the sum of their actual selected-axis extents. -/
theorem blocks_total {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis : Fin rank)
    (intervals : List (Interval extent length)) :
    total (blocks source input axis intervals) = intervals.length * source.shape length axis := by
  induction intervals with
  | nil => simp [blocks, total]
  | cons i is ih =>
    change source.shape length axis + total (blocks source input axis is) =
      (is.length + 1) * source.shape length axis
    rw [ih]
    simp [Nat.add_mul, Nat.add_comm]

/-- The result shape is the common slice shape with the destination extent multiplied. -/
theorem output_shape {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis : Fin rank)
    (intervals : List (Interval extent length)) :
    (destinationFrame source length axis).shape (total (blocks source input axis intervals)) =
      (destinationFrame source length axis).shape
        (intervals.length * source.shape length axis) := by
  rw [blocks_total]

/-- Exact extent on every axis of the concatenation result. -/
theorem output_shape_axis {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis i : Fin rank)
    (intervals : List (Interval extent length)) :
    (destinationFrame source length axis).shape (total (blocks source input axis intervals)) i =
      if i = axis then intervals.length * source.shape length axis else source.shape length i := by
  rw [blocks_total]
  rfl

/-- A coordinate in a listed block selects that exact slice in the original order. -/
theorem select_block {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis : Fin rank)
    (leading trailing : List (Interval extent length)) (chosen : Interval extent length)
    (rest : Index ((destinationFrame source length axis).shape 1))
    (coordinate : Fin (source.shape length axis))
    (bound : total (blocks source input axis leading) + coordinate.val <
      total (blocks source input axis (leading ++ chosen :: trailing))) :
    readAt (blocks source input axis (leading ++ chosen :: trailing)) rest
        (total (blocks source input axis leading) + coordinate.val) bound =
      (sliceBlock source input chosen.start length chosen.fits axis).values
        ((destinationFrame source length axis).withPosition rest coordinate) := by
  let b := sliceBlock source input chosen.start length chosen.fits axis
  have small : coordinate.val < total [b] := by simp [total, b, sliceBlock]
  have big : total (blocks source input axis leading) + coordinate.val <
      total (blocks source input axis leading ++ ([b] ++ blocks source input axis trailing)) := by
    simpa [blocks, b] using bound
  have h := readAt_middle (blocks source input axis leading) [b]
    (blocks source input axis trailing) rest coordinate.val small big
  simpa [blocks, b, readAt, total, sliceBlock, coordinate.isLt] using h

/-- The original input coordinate read by a particular actual slice. -/
def sourceIndex {rank extent length : Nat} (source : Frame rank) (axis : Fin rank)
    (interval : Interval extent length)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis))) :
    Index (source.shape extent) :=
  let sliced := destinationIndex source length axis index
  source.withPosition sliced ⟨interval.start + (source.position sliced).val, by
    have bound := (source.position sliced).isLt
    have fits := interval.fits
    omega⟩

/-- Selected output reads the source tensor at the original interval's offset. -/
theorem select_source {rank extent length : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape extent) α) (axis : Fin rank)
    (leading trailing : List (Interval extent length)) (chosen : Interval extent length)
    (rest : Index ((destinationFrame source length axis).shape 1))
    (coordinate : Fin (source.shape length axis))
    (bound : total (blocks source input axis leading) + coordinate.val <
      total (blocks source input axis (leading ++ chosen :: trailing))) :
    readAt (blocks source input axis (leading ++ chosen :: trailing)) rest
        (total (blocks source input axis leading) + coordinate.val) bound =
      input (sourceIndex source axis chosen
        ((destinationFrame source length axis).withPosition rest coordinate)) := by
  rw [select_block]
  rfl

/-- The input slice-axis coordinate is its original start plus the local coordinate. -/
theorem sourceIndex_split_value {rank extent length : Nat} (source : Frame rank)
    (axis : Fin rank) (interval : Interval extent length)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis))) :
    (sourceIndex source axis interval index source.axis).val =
      interval.start + (destinationIndex source length axis index source.axis).val := by
  simp [sourceIndex, Frame.withPosition, Frame.position]

/-- An interval beginning at a chunk multiple reads that chunk's original coordinate. -/
theorem sourceIndex_chunk_value {rank extent length : Nat} (source : Frame rank)
    (axis : Fin rank) (interval : Interval extent length) (chunk : Nat)
    (start : interval.start = chunk * length)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis))) :
    (sourceIndex source axis interval index source.axis).val =
      chunk * length + (destinationIndex source length axis index source.axis).val := by
  rw [sourceIndex_split_value, start]

/-- For a nonempty block, a prefix-block number and local coordinate give its quotient
and remainder. If blockExtent is zero, no such bounded coordinate exists. -/
theorem segment_quotient_remainder (number blockExtent : Nat) (coordinate : Fin blockExtent) :
    (number * blockExtent + coordinate.val) / blockExtent = number ∧
      (number * blockExtent + coordinate.val) % blockExtent = coordinate.val := by
  have positive : 0 < blockExtent := Nat.zero_lt_of_lt coordinate.isLt
  constructor
  · calc
      (number * blockExtent + coordinate.val) / blockExtent =
          (blockExtent * number + coordinate.val) / blockExtent := by rw [Nat.mul_comm number]
      _ = number + coordinate.val / blockExtent := Nat.mul_add_div positive number coordinate.val
      _ = number := by rw [Nat.div_eq_of_lt coordinate.isLt]; simp
  · calc
      (number * blockExtent + coordinate.val) % blockExtent =
          (coordinate.val + blockExtent * number) % blockExtent := by
            rw [Nat.mul_comm number, Nat.add_comm]
      _ = coordinate.val % blockExtent := Nat.add_mul_mod_self_left coordinate.val blockExtent number
      _ = coordinate.val := Nat.mod_eq_of_lt coordinate.isLt

#print axioms blocks_total
#print axioms output_shape
#print axioms output_shape_axis
#print axioms select_block
#print axioms select_source
#print axioms sourceIndex_split_value
#print axioms segment_quotient_remainder
#print axioms sourceIndex_chunk_value
end Heldout.OrderedSlices
