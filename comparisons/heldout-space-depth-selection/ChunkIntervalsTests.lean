module
import ChunkIntervals
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SliceTransport
  Heldout.OrderedSlices Heldout.ChunkIntervals
set_option autoImplicit false
namespace Heldout.ChunkIntervals.Tests

/-- The source order is adjacent and increasing for positive widths. -/
example : (intervals 3 2).map (fun x => x.start) = [0, 2, 4] := by decide
/-- One chunk starts at zero, while no chunks produce no intervals. -/
example : (intervals 1 7).map (fun x => x.start) = [0] := by decide
example : (intervals 0 7).isEmpty = true := by decide
/-- Zero-width chunks are valid and have repeated starts, not strictly increasing ones. -/
example : (intervals 3 0).map (fun x => x.start) = [0, 0, 0] := by decide
/-- An out-of-range index and a crossing slice cannot satisfy their guards. -/
example : ¬ (3 < 3) := by decide
example : ¬ (3 * 2 + 2 ≤ 3 * 2) := by decide

def frame : Frame 2 := ⟨fun _ => 3, ⟨0, by decide⟩⟩
def input : Tensor (frame.shape (3 * 2)) Nat :=
  fun i => 10 * (i ⟨0, by decide⟩).val + (i ⟨1, by decide⟩).val
def axis : Fin 2 := ⟨1, by decide⟩
def outputFrame := destinationFrame frame 2 axis
/-- The second chunk and second local concat coordinate locate output position four. -/
example : (chunkPosition frame input axis ⟨1, by decide⟩ ⟨1, by decide⟩).val = 4 := by decide

def outputIndex : Index (outputFrame.shape (total (chunkBlocks frame input axis))) :=
  fun i => ⟨if i.val = 0 then 1 else 4, (show ∀ i : Fin 2,
    (if i.val = 0 then 1 else 4) <
      (outputFrame.shape (total (chunkBlocks frame input axis))) i by decide) i⟩
/-- A real selected block retains both chunk and local source offsets: 2 + 1, and 1. -/
example : concatenate (chunkBlocks frame input axis) outputIndex = 31 := by decide
/-- A changed chunk selection is observably different. -/
example : concatenate (chunkBlocks frame input axis) outputIndex ≠ 11 := by decide

/-- Width zero leaves the split coordinate uninhabited despite positive concat extent. -/
def zeroInput : Tensor (frame.shape (3 * 0)) Nat := fun _ => 0
example : ¬ Nonempty (Index ((destinationFrame frame 0 axis).shape
    (total (chunkBlocks frame zeroInput axis)))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame frame 0 axis).shape
      (total (chunkBlocks frame zeroInput axis))) ⟨0, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨0, by decide⟩))
/-- Count zero has zero concat extent even when width is positive. -/
def noInput : Tensor (frame.shape (0 * 2)) Nat := fun _ => 0
example : total (chunkBlocks frame noInput axis) = 0 := by decide

/-- A zero extent on another axis also yields an empty output domain. -/
def emptyFrame : Frame 2 := ⟨fun _ => 0, ⟨0, by decide⟩⟩
def emptyInput : Tensor (emptyFrame.shape (3 * 2)) Nat := fun _ => 0
example : ¬ Nonempty (Index ((destinationFrame emptyFrame 2 axis).shape
    (total (chunkBlocks emptyFrame emptyInput axis)))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame emptyFrame 2 axis).shape
      (total (chunkBlocks emptyFrame emptyInput axis))) ⟨1, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨1, by decide⟩))
end Heldout.ChunkIntervals.Tests
namespace Heldout.ChunkIntervals.Tests
/-- Reordering the final two chunks is a well-formed but different sequence. -/
example : (intervals 3 2).map (fun x => x.start) ≠ [0, 4, 2] := by decide
end Heldout.ChunkIntervals.Tests
