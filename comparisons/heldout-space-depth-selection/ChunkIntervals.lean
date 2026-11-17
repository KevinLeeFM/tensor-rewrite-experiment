module
public import OrderedSlices

/-! Construct the source-style finite sequence of equal-sized legal intervals.
This is a bounded enumeration prerequisite, not the space-depth rewrite. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.ChunkIntervals
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SliceTransport Heldout.OrderedSlices

/-- The `i`th of `count` adjacent intervals of width `width`. -/
def interval (count width : Nat) (i : Fin count) : Interval (count * width) width where
  start := i.val * width
  fits := by
    calc
      i.val * width + width = (i.val + 1) * width := by simp [Nat.add_mul]
      _ ≤ count * width := Nat.mul_le_mul_right width (Nat.succ_le_of_lt i.isLt)

/-- Enumerate every index in increasing order, including an empty list at count zero. -/
def intervals (count width : Nat) : List (Interval (count * width) width) :=
  (List.finRange count).map (interval count width)

/-- The list contains exactly one interval for every bounded chunk index. -/
theorem intervals_length (count width : Nat) : (intervals count width).length = count := by
  simp [intervals]

/-- The interval at index `i` starts at the source loop's `i * width`. -/
theorem interval_start (count width : Nat) (i : Fin count) :
    ((intervals count width)[i.val]'(by simp [intervals, i.isLt])).start = i.val * width := by
  simp [intervals, interval]

/-- Enumerated starts are nondecreasing, including repeated starts when width is zero. -/
theorem starts_monotone (count width : Nat) (i j : Fin count) (ordered : i.val ≤ j.val) :
    ((intervals count width)[i.val]'(by simp [intervals, i.isLt])).start ≤
      ((intervals count width)[j.val]'(by simp [intervals, j.isLt])).start := by
  rw [interval_start, interval_start]
  exact Nat.mul_le_mul_right width ordered

/-- Positive-width intervals have strictly increasing starts. -/
theorem starts_strict (count width : Nat) (positive : 0 < width)
    (i j : Fin count) (ordered : i.val < j.val) :
    ((intervals count width)[i.val]'(by simp [intervals, i.isLt])).start <
      ((intervals count width)[j.val]'(by simp [intervals, j.isLt])).start := by
  rw [interval_start, interval_start]
  exact Nat.mul_lt_mul_of_pos_right ordered positive

/-- Adjacent chunks meet exactly at their boundary, including width zero. -/
theorem starts_contiguous (count width : Nat) (i j : Fin count) (next : j.val = i.val + 1) :
    ((intervals count width)[i.val]'(by simp [intervals, i.isLt])).start + width =
      ((intervals count width)[j.val]'(by simp [intervals, j.isLt])).start := by
  rw [interval_start, interval_start, next]
  simp [Nat.add_mul]

/-- The actual interval at a bounded index is exactly the constructed interval. -/
theorem interval_at (count width : Nat) (i : Fin count) :
    (intervals count width)[i.val]'(by simp [intervals, i.isLt]) = interval count width i := by
  simp [intervals]

/-- Decompose the ordered sequence at any actual bounded chunk index. -/
theorem intervals_decompose (count width : Nat) (i : Fin count) :
    intervals count width = (intervals count width).take i.val ++
      interval count width i :: (intervals count width).drop (i.val + 1) := by
  have bound : i.val < (intervals count width).length := by simp [intervals_length]
  calc
    intervals count width = (intervals count width).take i.val ++
        (intervals count width).drop i.val := (List.take_append_drop _ _).symm
    _ = (intervals count width).take i.val ++
        interval count width i :: (intervals count width).drop (i.val + 1) := by
          rw [← List.getElem_cons_drop bound, interval_at]

/-- There are exactly `i` earlier intervals before an existing `i`th chunk. -/
theorem leading_length (count width : Nat) (i : Fin count) :
    ((intervals count width).take i.val).length = i.val := by
  simp [intervals_length, Nat.min_eq_left (Nat.le_of_lt i.isLt)]

/-- Build actual concatenation blocks from that exact interval sequence. -/
def chunkBlocks {rank count width : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape (count * width)) α) (axis : Fin rank) :=
  blocks source input axis (intervals count width)

/-- The block list's total selected-axis extent is exactly count times one block extent. -/
theorem chunkBlocks_total {rank count width : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape (count * width)) α) (axis : Fin rank) :
    total (chunkBlocks source input axis) = count * source.shape width axis := by
  rw [chunkBlocks, blocks_total, intervals_length]

/-- The `i`th chunk and local concat coordinate determine an in-bounds output position. -/
def chunkPosition {rank count width : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape (count * width)) α) (axis : Fin rank)
    (i : Fin count) (coordinate : Fin (source.shape width axis)) :
    Fin (total (chunkBlocks source input axis)) :=
  ⟨i.val * source.shape width axis + coordinate.val, by
    rw [chunkBlocks_total]
    calc
      i.val * source.shape width axis + coordinate.val <
          i.val * source.shape width axis + source.shape width axis :=
        Nat.add_lt_add_left coordinate.isLt _
      _ = (i.val + 1) * source.shape width axis := by simp [Nat.add_mul]
      _ ≤ count * source.shape width axis :=
        Nat.mul_le_mul_right _ (Nat.succ_le_of_lt i.isLt)⟩

/-- The source-enumerated list selects the actual slice for any bounded chunk. -/
theorem chunk_select {rank count width : Nat} {α : Type} (source : Frame rank)
    (input : Tensor (source.shape (count * width)) α) (axis : Fin rank)
    (i : Fin count) (rest : Index ((destinationFrame source width axis).shape 1))
    (coordinate : Fin (source.shape width axis)) :
    readAt (chunkBlocks source input axis) rest
        (chunkPosition source input axis i coordinate).val
        (chunkPosition source input axis i coordinate).isLt =
      input (sourceIndex source axis (interval count width i)
        ((destinationFrame source width axis).withPosition rest coordinate)) := by
  let leading := (intervals count width).take i.val
  let trailing := (intervals count width).drop (i.val + 1)
  have decomposition : intervals count width = leading ++ interval count width i :: trailing :=
    intervals_decompose count width i
  have prior : total (blocks source input axis leading) = i.val * source.shape width axis := by
    rw [blocks_total]
    change ((intervals count width).take i.val).length * source.shape width axis =
      i.val * source.shape width axis
    rw [leading_length]
  have bound : total (blocks source input axis leading) + coordinate.val <
      total (blocks source input axis (leading ++ interval count width i :: trailing)) := by
    rw [prior, ← decomposition]
    exact (chunkPosition source input axis i coordinate).isLt
  have h := select_source source input axis leading trailing (interval count width i)
    rest coordinate bound
  simpa [← decomposition, prior, chunkBlocks, chunkPosition] using h

/-- The chosen chunk reads at `i * width` plus the bounded slice-axis coordinate. -/
theorem chunk_source_axis {rank count width : Nat} (source : Frame rank)
    (axis : Fin rank) (i : Fin count)
    (index : Index ((destinationFrame source width axis).shape (source.shape width axis))) :
    (sourceIndex source axis (interval count width i) index source.axis).val =
      i.val * width + (destinationIndex source width axis index source.axis).val := by
  exact sourceIndex_chunk_value source axis (interval count width i) i.val rfl index

#print axioms intervals_length
#print axioms interval_start
#print axioms starts_monotone
#print axioms starts_strict
#print axioms starts_contiguous
#print axioms interval_at
#print axioms intervals_decompose
#print axioms leading_length
#print axioms chunkBlocks_total
#print axioms chunk_select
#print axioms chunk_source_axis
end Heldout.ChunkIntervals
