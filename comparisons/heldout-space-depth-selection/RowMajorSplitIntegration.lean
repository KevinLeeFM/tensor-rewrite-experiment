module
public import RowMajorSplitProof
public import ActualSuffixProof
public import ActualTransportProof
public import PermutationCoordinate
@[expose] public section
set_option autoImplicit false
namespace Heldout.RowMajorSplitIntegration
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct
  TensorRewrite.Theory.Concatenation Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.IndexTransportAttempt Heldout.OriginalSplitConnection Heldout.ChunkIntervals
  Heldout.RecursiveShapeSplit Heldout.PlanShapeSplit Heldout.OrderedSlices
private theorem tailIndex_axis {m n : Nat} {shape : Shape (n + m)} (index : Index shape)
    (i : Fin n) :
    (tailIndex (m := m) (n := n) index i).val = (index ⟨m + i.val, by omega⟩).val := by
  induction m with
  | zero =>
    change (index i).val = (index ⟨0 + i.val, by omega⟩).val
    have hidx : i = (⟨0 + i.val, by omega⟩ : Fin n) := by
      apply Fin.ext
      simp
    exact congrArg (fun j => (index j).val) hidx
  | succ m ih =>
    change (tailIndex (m := m) (n := n) (fun j => index j.succ) i).val =
      (index ⟨m + 1 + i.val, by omega⟩).val
    have h := ih (fun j => index j.succ)
    have hidx : (⟨m + i.val + 1, by omega⟩ : Fin (n + (m + 1))) =
        ⟨m + 1 + i.val, by omega⟩ := by
      apply Fin.ext
      simp
      omega
    simpa [tailIndex] using h.trans (congrArg (fun j => (index j).val) hidx)


theorem row_eq {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    let source := splitFrame shape plan.axes.split
    let axis := concatAxis plan.axes
    let framed := framedInput shape plan.axes.split plan.splitProduct input
    let frame := concatFrame shape plan.axes plan.width
    let position := frame.position (replacementOuterIndex plan input out)
    let q := Fin.cast (chunkBlocks_total source framed axis) position
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) plan.axes.split.castSucc).val = (row q).val := by
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
  have selected := Heldout.TailHeadConnection.selected_chunk_coordinate plan input out
  have htransport := Heldout.ActualTransportProof.Goal_proved plan input out
  rw [Heldout.PermutationCoordinate.count_coordinate]
  dsimp only at selected ⊢
  rw [selected.1, htransport]
  have hp : 0 < shape (concatAxis plan.axes) := Nat.zero_lt_of_lt hbound
  rw [Nat.mul_comm (originalOuterIndex plan out plan.axes.moved).val,
    Nat.mul_add_div hp, Nat.div_eq_of_lt hbound]
  exact (Nat.add_zero _).symm

theorem width_eq {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) plan.axes.split.succ).val =
    (replacementOuterIndex plan input out plan.axes.split).val := by
  let m := plan.axes.moved.val
  let k := rank - m - 1
  have hm : m < plan.axes.split.val := moved_before_split plan.axes
  have hs := plan.axes.split.isLt
  have lRank : k + 2 = rank + 1 - m := by dsimp [k, m]; omega
  have rRank : k + 1 = rank - m := by dsimp [k, m]; omega
  let left : Shape (k + 2) := fun i => tailShape (m := m) (n := rank + 1 - m)
    (cutShape plan.axes inner) (Fin.cast lRank i)
  let right : Shape (k + 1) := fun i => tailShape (m := m) (n := rank - m)
    (replacementCutShape plan input) (Fin.cast rRank i)
  let li : Index left := fun i => tailIndex (m := m) (n := rank + 1 - m)
    (cutIndex plan.axes inner (originalOuterIndex plan out)) (Fin.cast lRank i)
  let ri : Index right := fun i => tailIndex (m := m) (n := rank - m)
    (replacementCutIndex plan input out) (Fin.cast rRank i)
  let i : Fin k := ⟨plan.axes.split.val - m - 1, by dsimp [k]; omega⟩
  have h := Heldout.ActualSuffixProof.Goal_proved plan input out i
  change (tailIndex (m := 2) (n := k) li i).val =
    (tailIndex (m := 1) (n := k) ri i).val at h
  rw [tailIndex_axis, tailIndex_axis] at h
  dsimp [li, ri] at h
  rw [tailIndex_axis, tailIndex_axis] at h
  have lidx : Fin.cast (cut_rank plan.axes)
      ⟨m + (Fin.cast lRank ⟨2 + i.val, by omega⟩).val, by omega⟩ = plan.axes.split.succ := by
    apply Fin.ext
    simp [i, m]
    omega
  have ridx : Fin.cast (replacement_cut_rank plan.axes)
      ⟨m + (Fin.cast rRank ⟨1 + i.val, by omega⟩).val, by omega⟩ = plan.axes.split := by
    apply Fin.ext
    simp [i, m]
    omega
  change (originalOuterIndex plan out (Fin.cast (cut_rank plan.axes)
      ⟨m + (Fin.cast lRank ⟨2 + i.val, by omega⟩).val, by omega⟩)).val =
    (replacementOuterIndex plan input out (Fin.cast (replacement_cut_rank plan.axes)
      ⟨m + (Fin.cast rRank ⟨1 + i.val, by omega⟩).val, by omega⟩)).val at h
  rw [lidx, ridx] at h
  rw [Heldout.IndexTransportAttempt.transpose_coordinate_value,
    Heldout.PermutationCoordinate.width_inverse]
  exact h

theorem factor : Heldout.ActualSplitFactorGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  have h := Heldout.RowMajorSplitProof.target_attempt plan out
  dsimp only at h
  rw [row_eq plan input out, width_eq plan input out] at h
  exact h

set_option backward.isDefEq.respectTransparency false in
theorem split : Heldout.RemainingAxisGoals.Split := by
  intro rank outerRank shape inner outer α plan input out
  apply Fin.ext
  have h := factor plan input out
  let source := splitFrame shape plan.axes.split
  let axis := concatAxis plan.axes
  let frame := concatFrame shape plan.axes plan.width
  let outerIndex := replacementOuterIndex plan input out
  let q := Fin.cast (chunkBlocks_total source
    (framedInput shape plan.axes.split plan.splitProduct input) axis) (frame.position outerIndex)
  change (originalIndex plan out plan.axes.split).val =
    (row q).val * plan.width + (outerIndex plan.axes.split).val at h
  change (originalIndex plan out plan.axes.split).val =
    (sourceIndex source axis (interval plan.count plan.width (row q))
      (frame.withPosition (frame.rest outerIndex) (column q)) source.axis).val
  have hs := sourceIndex_split_value source axis (interval plan.count plan.width (row q))
      (frame.withPosition (frame.rest outerIndex) (column q))
  rw [hs, h]
  congr 1
  have hdist : source.axis ≠ frame.axis := Ne.symm (concat_distinct plan.axes)
  simp [Heldout.SliceTransport.destinationIndex, Frame.withPosition, Frame.rest, hdist]
  rfl

#print axioms factor
#print axioms split
#print axioms row_eq
#print axioms width_eq
end Heldout.RowMajorSplitIntegration
