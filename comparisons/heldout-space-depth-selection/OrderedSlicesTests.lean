module
import OrderedSlices
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SliceTransport Heldout.OrderedSlices
set_option autoImplicit false
namespace Heldout.OrderedSlices.Tests

def frame : Frame 2 := ⟨fun _ => 3, ⟨0, by decide⟩⟩
def input : Tensor (frame.shape 4) Nat :=
  fun i => 10 * (i ⟨0, by decide⟩).val + (i ⟨1, by decide⟩).val
def intervals : List (Interval 4 2) := [⟨0, by decide⟩, ⟨2, by decide⟩]
def concatAxis : Fin 2 := ⟨1, by decide⟩
def concatFrame := destinationFrame frame 2 concatAxis
def outputIndex : Index (concatFrame.shape (total (blocks frame input concatAxis intervals))) :=
  fun i => ⟨if i.val = 0 then 0 else 3, (show ∀ i : Fin 2,
    (if i.val = 0 then 0 else 3) <
      (concatFrame.shape (total (blocks frame input concatAxis intervals))) i by decide) i⟩

/-- The second block starts exactly at concatenation coordinate three. -/
example : concatenate (blocks frame input concatAxis intervals) outputIndex = 20 := by decide
/-- Empty lists have no output extent on the concatenation axis. -/
example : total (blocks frame input concatAxis ([] : List (Interval 4 2))) = 0 := by decide
/-- The total is exactly two blocks of destination-axis extent three. -/
example : total (blocks frame input concatAxis intervals) = 6 := by decide

/-- A wrong concat axis remains well typed but changes the selected element. -/
def wrongAxis : Fin 2 := ⟨0, by decide⟩
def wrongFrame := destinationFrame frame 2 wrongAxis
def wrongIndex : Index (wrongFrame.shape (total (blocks frame input wrongAxis intervals))) :=
  fun i => ⟨if i.val = 0 then 1 else 0, (show ∀ i : Fin 2,
    (if i.val = 0 then 1 else 0) <
      (wrongFrame.shape (total (blocks frame input wrongAxis intervals))) i by decide) i⟩
example : concatenate (blocks frame input wrongAxis intervals) wrongIndex = 10 := by decide
example : concatenate (blocks frame input concatAxis intervals) outputIndex ≠
    concatenate (blocks frame input wrongAxis intervals) wrongIndex := by decide

/-- Zero-width slices retain a zero source-axis extent and no output coordinate. -/
def zeroIntervals : List (Interval 4 0) := [⟨0, by decide⟩, ⟨4, by decide⟩]
example : ¬ Nonempty (Index ((destinationFrame frame 0 concatAxis).shape
    (total (blocks frame input concatAxis zeroIntervals)))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame frame 0 concatAxis).shape
      (total (blocks frame input concatAxis zeroIntervals))) ⟨0, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨0, by decide⟩))

/-- A zero extent away from the sliced axis also leaves no output coordinate. -/
def emptyFrame : Frame 2 := ⟨fun _ => 0, ⟨0, by decide⟩⟩
def emptyInput : Tensor (emptyFrame.shape 4) Nat := fun _ => 0
example : ¬ Nonempty (Index ((destinationFrame emptyFrame 2 concatAxis).shape
    (total (blocks emptyFrame emptyInput concatAxis intervals)))) := by
  intro ⟨i⟩
  have zero : 0 = ((destinationFrame emptyFrame 2 concatAxis).shape
      (total (blocks emptyFrame emptyInput concatAxis intervals))) ⟨1, by decide⟩ := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i ⟨1, by decide⟩))
end Heldout.OrderedSlices.Tests
namespace Heldout.OrderedSlices.Tests
/-- The final coordinate of the first block precedes the second block. -/
def beforeBoundary : Index (concatFrame.shape (total (blocks frame input concatAxis intervals))) :=
  fun i => ⟨if i.val = 0 then 0 else 2, (show ∀ i : Fin 2,
    (if i.val = 0 then 0 else 2) <
      (concatFrame.shape (total (blocks frame input concatAxis intervals))) i by decide) i⟩
example : concatenate (blocks frame input concatAxis intervals) beforeBoundary = 2 := by decide
/-- No blocks means there is no bounded output index on the concatenation axis. -/
example : ¬ Nonempty (Index (concatFrame.shape
    (total (blocks frame input concatAxis ([] : List (Interval 4 2)))))) := by
  intro ⟨i⟩
  have zero : 0 = (concatFrame.shape
      (total (blocks frame input concatAxis ([] : List (Interval 4 2))))) concatAxis := by decide
  exact Fin.elim0 (Fin.cast zero.symm (i concatAxis))
end Heldout.OrderedSlices.Tests
