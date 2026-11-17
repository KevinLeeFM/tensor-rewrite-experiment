module
import SliceTransport

open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SliceTransport
set_option autoImplicit false
namespace Heldout.SliceTransport.Tests

/-- Split axis 0 and concatenation axis 1, with shape [4,3]. -/
def frame : Frame 2 := ⟨fun _ => 3, ⟨0, by decide⟩⟩
/-- Coordinate-sensitive input. -/
def input : Tensor (frame.shape 4) Nat :=
  fun i => 10 * (i ⟨0, by decide⟩).val + (i ⟨1, by decide⟩).val
/-- Nonzero slice index [1,2] within shape [2,3]. -/
def index : Index ((destinationFrame frame 2 ⟨1, by decide⟩).shape
    (frame.shape 2 ⟨1, by decide⟩)) := fun i =>
  ⟨if i.val = 0 then 1 else 2, (show ∀ i : Fin 2,
    (if i.val = 0 then 1 else 2) <
      ((destinationFrame frame 2 ⟨1, by decide⟩).shape
        (frame.shape 2 ⟨1, by decide⟩)) i by decide) i⟩

/-- Nontrivial coordinate keeps the offset and the other-axis coordinate. -/
example : (sliceBlock frame input 1 2 (by decide) ⟨1, by decide⟩).values index = 22 := by decide
/-- The incorrect unsliced input coordinate is observably different. -/
example : (sliceBlock frame input 1 2 (by decide) ⟨1, by decide⟩).values index ≠ 12 := by decide
/-- A slice may end exactly at its source extent. -/
example : (sliceBlock frame input 2 2 (by decide) ⟨1, by decide⟩).values index = 32 := by decide

/-- The zero-length slice has no index, rather than an invented default value. -/
example : ¬ Nonempty (Index ((destinationFrame frame 0 ⟨1, by decide⟩).shape
    (frame.shape 0 ⟨1, by decide⟩))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame frame 0 ⟨1, by decide⟩).shape
      (frame.shape 0 ⟨1, by decide⟩)) ⟨0, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨0, by decide⟩))

/-- A separate zero extent also makes the transported index domain empty. -/
def emptyFrame : Frame 2 := ⟨fun _ => 0, ⟨0, by decide⟩⟩
example : ¬ Nonempty (Index ((destinationFrame emptyFrame 2 ⟨1, by decide⟩).shape
    (emptyFrame.shape 2 ⟨1, by decide⟩))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame emptyFrame 2 ⟨1, by decide⟩).shape
      (emptyFrame.shape 2 ⟨1, by decide⟩)) ⟨1, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨1, by decide⟩))
end Heldout.SliceTransport.Tests
namespace Heldout.SliceTransport.Tests
/-- An empty slice is also legal at the end of the original extent. -/
example : (sliceBlock frame input 4 0 (by decide) ⟨1, by decide⟩).extent = 3 := by decide
/-- The construction is generic enough to permit the same frame axis too. -/
example : (sliceBlock frame input 1 2 (by decide) ⟨0, by decide⟩).extent = 2 := by decide
/-- A slice crossing the boundary cannot satisfy the required fit condition. -/
example : ¬ (3 + 2 ≤ 4) := by decide
end Heldout.SliceTransport.Tests
