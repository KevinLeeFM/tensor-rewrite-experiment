module
public import ActualTransportGoal
public import ActualAxisGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualTransportProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex
  TensorRewrite.Theory.Concatenation Heldout.SliceTransport
  Heldout.RecursiveShapeSplit Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.ChunkIntervals Heldout.OriginalSplitConnection Heldout.TailHeadConnection
  Heldout.ActualMergedProof Heldout.PlanShapeSplit

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

theorem Goal_proved : Heldout.ActualTransportGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  let m := plan.axes.moved.val
  let k := rank - m - 1
  have hm : m < plan.axes.split.val := Heldout.SourceFrame.moved_before_split plan.axes
  have hs := plan.axes.split.isLt
  have lRank : k + 2 = rank + 1 - m := by dsimp [k, m]; omega
  have rRank : k + 1 = rank - m := by dsimp [k, m]; omega
  let leftShape : Shape (k + 2) := fun i =>
    tailShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner) (Fin.cast lRank i)
  let rightShape : Shape (k + 1) := fun i =>
    tailShape (m := m) (n := rank - m) (replacementCutShape plan input) (Fin.cast rRank i)
  let leftIndex : Index leftShape := fun i =>
    tailIndex (m := m) (n := rank + 1 - m)
      (cutIndex plan.axes inner (originalOuterIndex plan out)) (Fin.cast lRank i)
  let rightIndex : Index rightShape := fun i =>
    tailIndex (m := m) (n := rank - m) (replacementCutIndex plan input out) (Fin.cast rRank i)
  have h := Heldout.ActualMergedProof.Goal_proved plan input out
  have hmrg : (preIndex (m := 1) (n := k) rightIndex 0).val =
      (preIndex (m := 2) (n := k) leftIndex 0).val *
        preShape (m := 2) (n := k) leftShape 1 +
      (preIndex (m := 2) (n := k) leftIndex 1).val := by
    simpa only [ActualMergedGoal.Goal] using h
  have rcast : Fin.cast rRank (0 : Fin (k + 1)) =
      (⟨0, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ : Fin (rank - m)) := by
    apply Fin.ext; simp
  have rightAxis : Fin.cast (replacement_cut_rank plan.axes)
      (⟨m + (Fin.cast rRank (0 : Fin (k + 1))).val,
        by have hm := Heldout.SourceFrame.moved_before_split plan.axes; omega⟩ : Fin ((rank - m) + m)) =
      concatAxis plan.axes := by
    apply Fin.ext
    simp [concatAxis, rcast, m]
  have hframe : ((concatFrame shape plan.axes plan.width).position
      (replacementOuterIndex plan input out)).val =
      (replacementOuterIndex plan input out (concatAxis plan.axes)).val := by
    change (Fin.cast (by simp [Heldout.SourceFrame.concatFrame,
        Heldout.SliceTransport.destinationFrame, Frame.shape])
      (replacementOuterIndex plan input out (concatAxis plan.axes))).val = _
    rfl
  have hright : (preIndex (m := 1) (n := k) rightIndex 0).val =
      (replacementOuterIndex plan input out (concatAxis plan.axes)).val := by
    change (rightIndex 0).val = _
    rw [tailIndex_axis]
    change (replacementCutIndex plan input out
      ⟨m + (Fin.cast rRank (0 : Fin (k + 1))).val, by omega⟩).val = _
    change (replacementOuterIndex plan input out
      (Fin.cast (replacement_cut_rank plan.axes)
        ⟨m + (Fin.cast rRank (0 : Fin (k + 1))).val, by omega⟩)).val = _
    exact congrArg (fun axis => (replacementOuterIndex plan input out axis).val) rightAxis
  have hpos : ((concatFrame shape plan.axes plan.width).position
      (replacementOuterIndex plan input out)).val = (preIndex (m := 1) (n := k) rightIndex 0).val :=
    hframe.trans hright.symm
  have l0 : Fin.cast lRank (0 : Fin (k + 2)) =
      (⟨0, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ : Fin (rank + 1 - m)) := by
    apply Fin.ext; simp
  have l1 : Fin.cast lRank (1 : Fin (k + 2)) =
      (⟨1, by have hm := Heldout.SourceFrame.moved_before_split plan.axes; have hs := plan.axes.split.isLt; omega⟩ : Fin (rank + 1 - m)) := by
    apply Fin.ext; simp
  have axis0 : Fin.cast (PlanShapeSplit.cut_rank plan.axes)
      (⟨m + 0, by omega⟩ : Fin ((rank + 1 - m) + m)) = plan.axes.moved := by
    apply Fin.ext; simp [m]
  have axis1 : Fin.cast (PlanShapeSplit.cut_rank plan.axes)
      (⟨m + 1, by omega⟩ : Fin ((rank + 1 - m) + m)) =
      (⟨m + 1, by omega⟩ : Fin (rank + 1)) := by
    apply Fin.ext; simp [m]
  have leftAxis0 : Fin.cast (PlanShapeSplit.cut_rank plan.axes)
      (⟨m + (Fin.cast lRank (0 : Fin (k + 2))).val,
        by have hm := Heldout.SourceFrame.moved_before_split plan.axes; omega⟩ : Fin ((rank + 1 - m) + m)) =
      plan.axes.moved := by
    apply Fin.ext
    simp [l0, m]
  have leftAxis1 : Fin.cast (PlanShapeSplit.cut_rank plan.axes)
      (⟨m + (Fin.cast lRank (1 : Fin (k + 2))).val,
        by have hm := Heldout.SourceFrame.moved_before_split plan.axes; omega⟩ : Fin ((rank + 1 - m) + m)) =
      (⟨m + 1, by omega⟩ : Fin (rank + 1)) := by
    apply Fin.ext
    simp [l1, m]
  have hleft0 : (preIndex (m := 2) (n := k) leftIndex 0).val =
      (originalOuterIndex plan out plan.axes.moved).val := by
    change (leftIndex 0).val = _
    rw [tailIndex_axis]
    change (cutIndex plan.axes inner (originalOuterIndex plan out)
      ⟨m + (Fin.cast lRank (0 : Fin (k + 2))).val, by omega⟩).val = _
    simp only [PlanShapeSplit.cutIndex]
    exact congrArg (fun axis => (originalOuterIndex plan out axis).val) leftAxis0
  have hleft1 : (preIndex (m := 2) (n := k) leftIndex 1).val =
      (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val := by
    change (leftIndex 1).val = _
    rw [tailIndex_axis]
    change (cutIndex plan.axes inner (originalOuterIndex plan out)
      ⟨m + (Fin.cast lRank (1 : Fin (k + 2))).val, by omega⟩).val = _
    simp only [PlanShapeSplit.cutIndex]
    exact congrArg (fun axis => (originalOuterIndex plan out axis).val) leftAxis1
  have hwidth : preShape (m := 2) (n := k) leftShape 1 = shape (concatAxis plan.axes) := by
    change tailShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner)
      (Fin.cast lRank (1 : Fin (k + 2))) = _
    rw [l1]
    exact Heldout.TailHeadConnection.original_tail_moved plan
  calc
    ((concatFrame shape plan.axes plan.width).position (replacementOuterIndex plan input out)).val =
        (preIndex (m := 1) (n := k) rightIndex 0).val := hpos
    _ = (preIndex (m := 2) (n := k) leftIndex 0).val * preShape (m := 2) (n := k) leftShape 1 +
          (preIndex (m := 2) (n := k) leftIndex 1).val := hmrg
    _ = (originalOuterIndex plan out plan.axes.moved).val * shape (concatAxis plan.axes) +
          (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by omega⟩).val := by simp [hleft0, hwidth, hleft1]

#print axioms Goal_proved

/-! Worker timing ledger (UTC). Parent assignment clock started at 17:42:37.

Compiler attempts on Goal/Proof, in order; end/duration was not captured for the
short exploratory invocations (each returned at the next tool boundary):
17:44:21 Goal module: success.
17:44:51 invalid import `ActualAxisProof` (draft is only .lean.txt): failure; import removed.
17:45:15 local change elaboration: failure.
17:45:23 merged equation extraction attempt: failure; residual inspected.
17:46:29 path/edit attempt: failure.
17:47:09 path/edit attempt: failure.
17:47:28 rank-cast conversion attempt: failure.
17:48:10 cast conversion attempt: failure.
17:48:15 diagnostic replay: failure.
17:48:47 explicit rank-cast attempt: failure.
17:49:53 composed cast attempt: failure.
17:50:53 explicit actual-axis cast attempt: failure.
17:51:13 frame-position normalization: failure.
17:51:29 frame-position normalization: failure.
17:52:36 final frame-position normalization attempt: failure at that boundary.
17:52:48 corrected `rfl` normalization: success.
17:53:56 clean proof replay: success, no warnings; axiom set printed.
17:55:31 `lean -o /tmp/space-transport-worker/ActualTransportProof.olean`:
  started 17:55:31.636 UTC, ended 17:55:32.765 UTC, 1.129s, rc=0.
17:58:16 axes direct-simp attempt:
  started 17:58:16.867 UTC, ended 17:58:17.390 UTC, 0.523s, rc=1.

No worker subprocesses or review were run. Active reasoning time is not
instrumented separately; no token-cost or speedup measurement was made.
-/
end Heldout.ActualTransportProof
