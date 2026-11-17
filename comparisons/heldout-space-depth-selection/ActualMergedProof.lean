module
public import ActualMergedGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualMergedProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex
  Heldout.SpaceDepthCandidate Heldout.RecursiveShapeSplit
  Heldout.SourceFrame Heldout.ChunkIntervals Heldout.TailCoordinateConnection
  Heldout.TailHeadConnection Heldout.TailCountIntegration
  Heldout.WorkerSuffix
  Heldout.PlanShapeSplit Heldout.OriginalSplitConnection
  Heldout.MergedHeadConnection

theorem Goal_proved : Heldout.ActualMergedGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  dsimp only
  apply merged_head_of_tail_packing
  · simp only [elementCount, preShape, Fin.cases_zero, Fin.cases_succ]
    have hm := Heldout.SourceFrame.moved_before_split plan.axes
    have hs := plan.axes.split.isLt
    have rRank : rank - plan.axes.moved.val - 1 + 1 = rank - plan.axes.moved.val := by omega
    have lRank : rank - plan.axes.moved.val - 1 + 2 = rank + 1 - plan.axes.moved.val := by omega
    have r0 : Fin.cast rRank
        (0 : Fin (rank - plan.axes.moved.val - 1 + 1)) =
        ⟨0, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ := by
      apply Fin.ext
      simp
    have l0 : Fin.cast lRank
        (0 : Fin (rank - plan.axes.moved.val - 1 + 2)) =
        ⟨0, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ := by
      apply Fin.ext
      simp
    have l1 : Fin.cast lRank
        (Fin.succ 0 : Fin (rank - plan.axes.moved.val - 1 + 2)) =
        ⟨1, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ := by
      apply Fin.ext
      simp
    rw [r0, l0, l1]
    simpa only [Nat.mul_one] using (tail_extents_merge plan input).symm
  · let k := rank - plan.axes.moved.val - 1
    have hm := Heldout.SourceFrame.moved_before_split plan.axes
    have hs := plan.axes.split.isLt
    have lRank : k + 2 = rank + 1 - plan.axes.moved.val := by dsimp [k]; omega
    have rRank : k + 1 = rank - plan.axes.moved.val := by dsimp [k]; omega
    let left : Shape (k + 2) := fun i => tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner) (Fin.cast lRank i)
    let right : Shape (k + 1) := fun i => tailShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input) (Fin.cast rRank i)
    change elementCount (tailShape (m := 2) (n := k) left) =
      elementCount (tailShape (m := 1) (n := k) right)
    apply congrArg elementCount
    funext i
    rw [tail_axis (m := 2) (n := k) left i, tail_axis (m := 1) (n := k) right i]
    simp only [left, right]
    have hshape : replacementCutShape plan input =
        replacementCutShape plan (fun _ => (0 : Nat)) := by
      funext j
      simp only [replacementCutShape]
      rw [chunkBlocks_total, chunkBlocks_total]
    rw [hshape]
    have li : Fin.cast lRank (⟨2 + i.val, by omega⟩ : Fin (k + 2)) =
        ⟨2 + i.val, by omega⟩ := by
      apply Fin.ext
      simp
    have ri : Fin.cast rRank (⟨1 + i.val, by omega⟩ : Fin (k + 1)) =
        ⟨1 + i.val, by omega⟩ := by
      apply Fin.ext
      simp
    rw [li, ri]
    exact suffix_extents plan i
  · let k := rank - plan.axes.moved.val - 1
    have hm := Heldout.SourceFrame.moved_before_split plan.axes
    have hs := plan.axes.split.isLt
    have lRank : k + 2 = rank + 1 - plan.axes.moved.val := by dsimp [k]; omega
    have rRank : k + 1 = rank - plan.axes.moved.val := by dsimp [k]; omega
    let left : Shape (k + 2) := fun i => tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner) (Fin.cast lRank i)
    let right : Shape (k + 1) := fun i => tailShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input) (Fin.cast rRank i)
    let leftIndex : Index left := fun i => tailIndex (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutIndex plan.axes inner (originalOuterIndex plan out))
      (Fin.cast lRank i)
    let rightIndex : Index right := fun i => tailIndex (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutIndex plan input out) (Fin.cast rRank i)
    change (linearize left leftIndex).val = (linearize right rightIndex).val
    calc
      (linearize left leftIndex).val =
          (linearize (tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
            (cutShape plan.axes inner))
            (tailIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
              (cutIndex plan.axes inner (originalOuterIndex plan out)))).val :=
        rank_cast_packed lRank _ _
      _ = (linearize (tailShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
            (replacementCutShape plan input))
            (tailIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
              (replacementCutIndex plan input out))).val :=
        actual_tail_packed_values_equal plan input out
      _ = (linearize right rightIndex).val := (rank_cast_packed rRank _ _).symm
end Heldout.ActualMergedProof
#print axioms Heldout.ActualMergedProof.Goal_proved
