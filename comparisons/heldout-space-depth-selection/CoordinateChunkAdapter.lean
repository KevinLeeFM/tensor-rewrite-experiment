module
public import CoordinateBridge
public import ChunkIntervals

/-! A generic product coordinate selects a source-enumerated block. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.CoordinateChunkAdapter
open TensorRewrite.Pilot TensorRewrite.Pilot.FiniteProduct
  TensorRewrite.Theory.Concatenation Heldout.SliceTransport Heldout.ChunkIntervals

/-- Every admitted concatenation coordinate is the chunk-position of its quotient and remainder. -/
theorem chunkPosition_of_coordinate {rank count width : Nat} {α : Type}
    (source : Frame rank) (input : Tensor (source.shape (count * width)) α)
    (axis : Fin rank) (p : Fin (total (chunkBlocks source input axis))) :
    let q := Fin.cast (chunkBlocks_total source input axis) p
    chunkPosition source input axis (row q) (column q) = p := by
  apply Fin.ext
  exact Nat.div_add_mod' p.val (source.shape width axis)

/-- Reading any valid position selects the source slice indexed by quotient and remainder. -/
theorem select_coordinate {rank count width : Nat} {α : Type}
    (source : Frame rank) (input : Tensor (source.shape (count * width)) α)
    (axis : Fin rank) (p : Fin (total (chunkBlocks source input axis)))
    (rest : Index ((destinationFrame source width axis).shape 1)) :
    let q := Fin.cast (chunkBlocks_total source input axis) p
    readAt (chunkBlocks source input axis) rest p.val p.isLt =
      input (Heldout.OrderedSlices.sourceIndex source axis (interval count width (row q))
        ((destinationFrame source width axis).withPosition rest (column q))) := by
  have h := chunk_select source input axis
    (row (Fin.cast (chunkBlocks_total source input axis) p)) rest
    (column (Fin.cast (chunkBlocks_total source input axis) p))
  rw [chunkPosition_of_coordinate source input axis p] at h
  exact h

#print axioms chunkPosition_of_coordinate
#print axioms select_coordinate
end Heldout.CoordinateChunkAdapter
