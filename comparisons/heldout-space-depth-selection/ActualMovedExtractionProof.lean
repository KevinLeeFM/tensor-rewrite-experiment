module
public import ActualMovedExtractionGoal
public import ActualTransportProof
public import PermutationCoordinate
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualMovedExtractionProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Theory.Concatenation
  TensorRewrite.Pilot.FiniteProduct
  Heldout.ActualMovedExtractionGoal Heldout.ActualTransportGoal Heldout.ActualTransportProof
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.IndexTransportAttempt
  Heldout.OriginalSplitConnection Heldout.SliceTransport Heldout.OrderedSlices
  Heldout.ChunkIntervals Heldout.PermutationCoordinate

private theorem sourceIndex_other_axis_value {rank extent length : Nat}
    (source : Frame rank) (axis i : Fin rank) (interval : Interval extent length)
    (index : Index ((destinationFrame source length axis).shape (source.shape length axis)))
    (different : i ≠ source.axis) :
    (sourceIndex source axis interval index i).val = (index i).val := by
  simp [sourceIndex, destinationIndex, Frame.withPosition, Frame.position, different]

theorem ReplacementGoal_proved : ReplacementGoal := by
  intro rank outerRank shape inner outer α plan input out
  have htransport := ActualTransportProof.Goal_proved plan input out
  have hmoved :
      ((concatFrame shape plan.axes plan.width).position
        (replacementOuterIndex plan input out)).val =
        (originalOuterIndex plan out plan.axes.moved).val * shape (concatAxis plan.axes) +
          (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
            have hm := moved_before_split plan.axes
            have hs := plan.axes.split.isLt
            omega⟩).val := htransport
  have hsucc : plan.axes.permutation.outputToInput
      (⟨plan.axes.moved.val + 1, by
        have hm := moved_before_split plan.axes
        have hs := plan.axes.split.isLt
        omega⟩ : Fin (rank + 1)) = (concatAxis plan.axes).castSucc := by
    apply Fin.ext
    have hm := moved_before_split plan.axes
    have h := Heldout.PermutationRegions.between_moved_split plan.axes
      (concatAxis plan.axes).succ (by simp [concatAxis])
      (by simp [concatAxis]; omega)
    have hv : (plan.axes.permutation.outputToInput
        (⟨plan.axes.moved.val + 1, by have hm := moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ : Fin (rank + 1))).val + 1 =
        plan.axes.moved.val + 1 := by simpa [concatAxis] using h
    change (plan.axes.permutation.outputToInput
      (⟨plan.axes.moved.val + 1, by have hm := moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ : Fin (rank + 1))).val = plan.axes.moved.val
    omega
  have hbound : (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
      have hm := moved_before_split plan.axes
      have hs := plan.axes.split.isLt
      omega⟩).val < shape (concatAxis plan.axes) := by
    let d : Fin (rank + 1) := ⟨plan.axes.moved.val + 1, by
      have hm := moved_before_split plan.axes
      have hs := plan.axes.split.isLt
      omega⟩
    have hi := (originalOuterIndex plan out d).isLt
    change (originalOuterIndex plan out d).val <
      inner (plan.axes.permutation.outputToInput d) at hi
    rw [hsucc] at hi
    have hshape := plan.prefixAxes (concatAxis plan.axes) (moved_before_split plan.axes)
    simpa [d, transposedShape, hshape] using hi
  let source := splitFrame shape plan.axes.split
  let axis := concatAxis plan.axes
  let frame := concatFrame shape plan.axes plan.width
  let outerIndex := replacementOuterIndex plan input out
  have hsameAxis : axis = frame.axis := rfl
  let q := Fin.cast (chunkBlocks_total source
    (framedInput shape plan.axes.split plan.splitProduct input) axis) (frame.position outerIndex)
  have hcoord : (replacementIndex plan input out axis).val = (column q).val := by
    change (sourceIndex source axis (interval plan.count plan.width (row q))
      (frame.withPosition (frame.rest outerIndex) (column q)) axis).val = _
    have hs := sourceIndex_other_axis_value source axis axis
      (interval plan.count plan.width (row q))
      (frame.withPosition (frame.rest outerIndex) (column q))
      (Heldout.SourceFrame.concat_distinct plan.axes)
    simpa [Frame.withPosition, hsameAxis, Fin.val_cast] using hs
  have hq : (column q).val = (frame.position outerIndex).val % shape axis := by
    have selected := Heldout.TailHeadConnection.selected_chunk_coordinate plan input out
    change (row q).val = _ ∧ (column q).val = _ at selected
    exact selected.2
  rw [hcoord, hq]
  rw [htransport]
  have hm := moved_before_split plan.axes
  have hs := plan.axes.split.isLt
  have hmod : ((originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val %
      shape axis) = (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val :=
    Nat.mod_eq_of_lt hbound
  calc
    _ = ((originalOuterIndex plan out plan.axes.moved).val * shape axis +
      (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val) % shape axis := rfl
    _ = ((originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val +
      shape axis * (originalOuterIndex plan out plan.axes.moved).val) % shape axis := by
        rw [Nat.mul_comm, Nat.add_comm]
    _ = (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val := by
      rw [Nat.add_mul_mod_self_left, hmod]

#print axioms ReplacementGoal_proved
end Heldout.ActualMovedExtractionProof
