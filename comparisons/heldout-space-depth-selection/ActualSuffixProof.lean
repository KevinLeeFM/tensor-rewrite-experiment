module
public import ActualSuffixGoal
public import ActualMergedProof
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualSuffixProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct
  Heldout.SpaceDepthCandidate Heldout.RecursiveShapeSplit Heldout.SourceFrame
  Heldout.ChunkIntervals Heldout.TailCoordinateConnection Heldout.TailHeadConnection
  Heldout.TailCountIntegration Heldout.PlanShapeSplit Heldout.OriginalSplitConnection
  Heldout.WorkerIndexJoin Heldout.MergedHeadConnection Heldout.WorkerSuffix

theorem Goal_proved : Heldout.ActualSuffixGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  dsimp only
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
  let ls : Shape k := tailShape (m := 2) (n := k) left
  let rs : Shape k := tailShape (m := 1) (n := k) right
  let lsi : Index ls := tailIndex (m := 2) (n := k) li
  let rsi : Index rs := tailIndex (m := 1) (n := k) ri
  have sameSuffix : ls = rs := by
    funext i
    change tailShape (m := 2) (n := k) left i = tailShape (m := 1) (n := k) right i
    rw [tail_axis, tail_axis]
    simp only [left, right]
    have lcast : Fin.cast lRank (⟨2 + i.val, by dsimp [k]; omega⟩ : Fin (k + 2)) =
        (⟨2 + i.val, by dsimp [k, m]; omega⟩ : Fin (rank + 1 - m)) := by
      apply Fin.ext
      simp
    have rcast : Fin.cast rRank (⟨1 + i.val, by dsimp [k]; omega⟩ : Fin (k + 1)) =
        (⟨1 + i.val, by dsimp [k, m]; omega⟩ : Fin (rank - m)) := by
      apply Fin.ext
      simp
    rw [lcast, rcast]
    have hshape : replacementCutShape plan input = replacementCutShape plan (fun _ => (0 : Nat)) := by
      funext j
      simp only [replacementCutShape]
      rw [chunkBlocks_total, chunkBlocks_total]
    rw [hshape]
    exact suffix_extents plan i
  have sameRows : elementCount (preShape (m := 2) (n := k) left) =
      elementCount (preShape (m := 1) (n := k) right) := by
    simp only [elementCount, preShape, Fin.cases_zero, Fin.cases_succ]
    have r0 : Fin.cast rRank (0 : Fin (k + 1)) = ⟨0, by dsimp [k,m]; omega⟩ := by apply Fin.ext; simp
    have l0 : Fin.cast lRank (0 : Fin (k + 2)) = ⟨0, by dsimp [k,m]; omega⟩ := by apply Fin.ext; simp
    have l1 : Fin.cast lRank (Fin.succ 0 : Fin (k + 2)) = ⟨1, by dsimp [k,m]; omega⟩ := by apply Fin.ext; simp
    simp only [left, right]
    rw [r0, l0, l1]
    simpa only [Nat.mul_one] using (tail_extents_merge plan input).symm
  have sameCols : elementCount ls = elementCount rs := congrArg elementCount sameSuffix
  have packedTail : (linearize (tailShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner))
        (tailIndex (m := m) (n := rank + 1 - m) (cutIndex plan.axes inner (originalOuterIndex plan out)))).val =
      (linearize (tailShape (m := m) (n := rank - m) (replacementCutShape plan input))
        (tailIndex (m := m) (n := rank - m) (replacementCutIndex plan input out))).val :=
    actual_tail_packed_values_equal plan input out
  have packed : (linearize left li).val = (linearize right ri).val := by
    dsimp [left, right, li, ri]
    exact (rank_cast_packed lRank _ _).trans
      (packedTail.trans (rank_cast_packed rRank _ _).symm)
  have packedSplit := packed_component_values sameRows sameCols
    (linearize (preShape (m := 2) (n := k) left) (preIndex (m := 2) (n := k) li))
    (linearize (preShape (m := 1) (n := k) right) (preIndex (m := 1) (n := k) ri))
    (linearize ls lsi) (linearize rs rsi) (by
      rw [← full_linearize_split li, ← full_linearize_split ri]
      exact packed)
  have hpacked : (linearize ls lsi).val = (linearize rs rsi).val := packedSplit.2
  -- Transfer the right packed coordinate to the left shape, then recover its coordinates.
  have hpos : linearize ls lsi =
      Fin.cast (congrArg elementCount sameSuffix.symm) (linearize rs rsi) := by
    apply Fin.ext
    simpa only [Fin.val_cast] using hpacked
  have hcastPacked := linearize_transport sameSuffix.symm rsi
  have hsamePacked : linearize ls lsi =
      linearize ls (fun i => Fin.cast (congrFun sameSuffix.symm i) (rsi i)) :=
    hpos.trans hcastPacked.symm
  have : lsi = fun i => Fin.cast (congrFun sameSuffix.symm i) (rsi i) := by
    have hcoords := congrArg (delinearize ls) hsamePacked
    simpa only [delinearize_linearize] using hcoords
  intro i
  simpa using congrArg Fin.val (congrFun this i)

#print axioms Goal_proved
end Heldout.ActualSuffixProof
