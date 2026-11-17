module
public import ActualMovedExtractionGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.OriginalCoordinateProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
  TensorRewrite.Pilot.FiniteProduct
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.IndexTransportAttempt
  Heldout.OriginalSplitConnection Heldout.RecursiveShapeSplit
  Heldout.WorkerIndexJoin

private theorem prefixIndex_eq_of_packed_eq {m n₁ n₂ : Nat}
    (left : Shape (n₁ + m)) (right : Shape (n₂ + m))
    (li : Index left) (ri : Index right)
    (samePrefix : preShape (m := m) (n := n₁) left =
      preShape (m := m) (n := n₂) right)
    (sameTailCount : elementCount (tailShape (m := m) (n := n₁) left) =
      elementCount (tailShape (m := m) (n := n₂) right))
    (samePacked : (linearize left li).val = (linearize right ri).val) :
    ∀ i : Fin m, (preIndex (m := m) (n := n₁) li i).val =
      (preIndex (m := m) (n := n₂) ri i).val := by
  have samePrefixCount := congrArg elementCount samePrefix
  have splitLeft := full_linearize_split li
  have splitRight := full_linearize_split ri
  have joined :
      (FiniteProduct.join (linearize (preShape (m := m) (n := n₁) left) (preIndex (m := m) (n := n₁) li))
        (linearize (tailShape (m := m) (n := n₁) left) (tailIndex (m := m) (n := n₁) li))).val =
      (FiniteProduct.join (linearize (preShape (m := m) (n := n₂) right) (preIndex (m := m) (n := n₂) ri))
        (linearize (tailShape (m := m) (n := n₂) right) (tailIndex (m := m) (n := n₂) ri))).val :=
    splitLeft.symm.trans (samePacked.trans splitRight)
  have components := packed_component_values samePrefixCount sameTailCount
    (linearize (preShape (m := m) (n := n₁) left) (preIndex (m := m) (n := n₁) li))
    (linearize (preShape (m := m) (n := n₂) right) (preIndex (m := m) (n := n₂) ri))
    (linearize (tailShape (m := m) (n := n₁) left) (tailIndex (m := m) (n := n₁) li))
    (linearize (tailShape (m := m) (n := n₂) right) (tailIndex (m := m) (n := n₂) ri)) joined
  let leftPre := preIndex (m := m) (n := n₁) li
  let rightPre := preIndex (m := m) (n := n₂) ri
  let transported : Index (preShape (m := m) (n := n₂) right) :=
    fun i => Fin.cast (congrFun samePrefix i) (leftPre i)
  have transportedPacked := linearize_transport samePrefix leftPre
  have hpacked : (linearize (preShape (m := m) (n := n₂) right) transported).val =
      (linearize (preShape (m := m) (n := n₂) right) rightPre).val := by
    have casted := congrArg Fin.val transportedPacked
    simpa [Fin.val_cast] using casted.trans components.1
  have hindices : transported = rightPre := by
    have hfin := Fin.ext hpacked
    calc
      transported = delinearize (preShape (m := m) (n := n₂) right)
          (linearize (preShape (m := m) (n := n₂) right) transported) :=
        (delinearize_linearize _ _).symm
      _ = delinearize (preShape (m := m) (n := n₂) right)
          (linearize (preShape (m := m) (n := n₂) right) rightPre) := congrArg _ hfin
      _ = rightPre := delinearize_linearize _ _
  intro i
  have value := congrArg (fun f : Index (preShape (m := m) (n := n₂) right) => (f i).val) hindices
  simpa [transported, leftPre, rightPre, Fin.val_cast] using value

private theorem preIndex_axis {m n : Nat} {shape : Shape (n + m)}
    (index : Index shape) (i : Fin m) :
    (preIndex (m := m) (n := n) index i).val =
      (index ⟨i.val, by omega⟩).val := by
  induction m with
  | zero => exact Fin.elim0 i
  | succ m ih =>
    refine Fin.cases ?_ (fun i => ?_) i
    · rfl
    · change (preIndex (m := m) (n := n) (fun j => index j.succ) i).val =
        (index ⟨i.val.succ, by omega⟩).val
      have h := ih (fun j => index j.succ) i
      simpa using h

theorem Goal_proved : Heldout.ActualMovedExtractionGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  let m := plan.axes.moved.val + 1
  have before := moved_before_split plan.axes
  have splitBound := plan.axes.split.isLt
  have mLe : m ≤ rank := by dsimp [m]; omega
  have leftRank : (rank - m) + m = rank := Nat.sub_add_cancel mLe
  have rightRank : (rank + 1 - m) + m = rank + 1 := by
    apply Nat.sub_add_cancel
    dsimp [m]
    omega
  let leftShape : Shape ((rank - m) + m) := fun i => shape (Fin.cast leftRank i)
  let rightShape : Shape ((rank + 1 - m) + m) := fun i => inner (Fin.cast rightRank i)
  let leftIndex : Index leftShape := fun i => originalIndex plan out (Fin.cast leftRank i)
  let rightIndex : Index rightShape := fun i =>
    Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank i)
  have prefixEq : preShape (m := m) (n := rank - m) leftShape =
      preShape (m := m) (n := rank + 1 - m) rightShape := by
    funext i
    rw [Heldout.WorkerIndexPrefix.pre_axis, Heldout.WorkerIndexPrefix.pre_axis]
    let j : Fin rank := ⟨i.val, by omega⟩
    have leftCast : Fin.cast leftRank ⟨i.val, by omega⟩ = j := by
      apply Fin.ext
      rfl
    have rightCast : Fin.cast rightRank ⟨i.val, by omega⟩ = j.castSucc := by
      apply Fin.ext
      rfl
    change shape (Fin.cast leftRank ⟨i.val, by omega⟩) =
      inner (Fin.cast rightRank ⟨i.val, by omega⟩)
    rw [leftCast, rightCast]
    exact (plan.prefixAxes j (by
      have hm := moved_before_split plan.axes
      have hi : i.val < plan.axes.moved.val + 1 := by simp [m]
      have hi' : i.val ≤ plan.axes.moved.val := Nat.le_of_lt_succ hi
      exact Nat.lt_of_le_of_lt hi' hm)).symm
  have leftCount : elementCount leftShape = elementCount shape := by
    exact Heldout.TailCountIntegration.rank_cast_count leftRank shape
  have rightCount : elementCount rightShape = elementCount inner := by
    exact Heldout.TailCountIntegration.rank_cast_count rightRank inner
  have sameCount : elementCount leftShape = elementCount rightShape :=
    leftCount.trans (plan.innerCount.trans rightCount.symm)
  have prefixCount := congrArg elementCount prefixEq
  have leftSplit := full_count_split leftShape
  have rightSplit := full_count_split rightShape
  have products :
      elementCount (preShape (m := m) (n := rank - m) leftShape) *
          elementCount (tailShape (m := m) (n := rank - m) leftShape) =
      elementCount (preShape (m := m) (n := rank + 1 - m) rightShape) *
          elementCount (tailShape (m := m) (n := rank + 1 - m) rightShape) := by
    calc
      _ = elementCount leftShape := leftSplit.symm
      _ = elementCount rightShape := sameCount
      _ = _ := rightSplit
  have prefixPositive : 0 < elementCount (preShape (m := m) (n := rank - m) leftShape) :=
    Nat.zero_lt_of_lt (linearize _ (preIndex (m := m) (n := rank - m) leftIndex)).isLt
  have tailsEqual := Nat.mul_left_cancel prefixPositive (by
    simpa [prefixCount] using products)
  have packedEqual : (linearize leftShape leftIndex).val = (linearize rightShape rightIndex).val := by
    calc
      _ = (linearize shape (originalIndex plan out)).val := by
        simpa [leftShape, leftIndex] using
          (Heldout.OriginalSplitConnection.rank_cast_packed leftRank shape
            (originalIndex plan out))
      _ = (linearize inner
          (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
            (originalOuterIndex plan out))).val := by
        simp only [originalIndex, reshapeIndex, originalOuterIndex,
          LinearIndex.linearize_delinearize]
      _ = _ := by
        simpa [rightShape, rightIndex] using (Heldout.OriginalSplitConnection.rank_cast_packed rightRank inner
          (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
            (originalOuterIndex plan out))).symm
  have prefixIndices := prefixIndex_eq_of_packed_eq leftShape rightShape leftIndex rightIndex
    prefixEq tailsEqual packedEqual
  let targetAxis : Fin m := ⟨plan.axes.moved.val, by dsimp [m]; omega⟩
  have targetAxisEq : targetAxis = ⟨plan.axes.moved.val, by omega⟩ := by
    apply Fin.ext
    rfl
  have hcoord := prefixIndices targetAxis
  rw [targetAxisEq] at hcoord
  have leftAxis : Fin.cast leftRank ⟨plan.axes.moved.val, by omega⟩ = concatAxis plan.axes := by
    apply Fin.ext
    simp [concatAxis]
  have rightAxis : Fin.cast rightRank ⟨plan.axes.moved.val, by omega⟩ =
      (concatAxis plan.axes).castSucc := by
    apply Fin.ext
    simp [concatAxis]
  let d : Fin (rank + 1) := ⟨plan.axes.moved.val + 1, by
    have := moved_before_split plan.axes
    have := plan.axes.split.isLt
    omega⟩
  have between := Heldout.PermutationRegions.between_moved_split plan.axes d
    (by dsimp [d]; omega) (by have := moved_before_split plan.axes; have := plan.axes.split.isLt; dsimp [d]; omega)
  have outAxis : plan.axes.permutation.outputToInput d = (concatAxis plan.axes).castSucc := by
    have outputValue : (plan.axes.permutation.outputToInput d).val = plan.axes.moved.val := by
      have hd : d.val = plan.axes.moved.val + 1 := rfl
      omega
    apply Fin.ext
    simpa [concatAxis] using outputValue
  have movedOut : plan.axes.permutation.inputToOutput ((concatAxis plan.axes).castSucc) = d := by
    calc
      _ = plan.axes.permutation.inputToOutput (plan.axes.permutation.outputToInput d) :=
        congrArg plan.axes.permutation.inputToOutput outAxis.symm
      _ = d := plan.axes.permutation.input_output d
  have leftValue : (preIndex (m := m) (n := rank - m) leftIndex targetAxis).val =
      (originalIndex plan out (concatAxis plan.axes)).val := by
    rw [targetAxisEq, preIndex_axis]
    exact congrArg (fun j => (originalIndex plan out j).val) leftAxis
  have rightValue : (preIndex (m := m) (n := rank + 1 - m) rightIndex targetAxis).val =
      (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
        have := moved_before_split plan.axes
        have := plan.axes.split.isLt
        omega⟩).val := by
    rw [targetAxisEq, preIndex_axis]
    change (Tensor.transposeIndex plan.axes.permutation
      (transpose_extents inner plan.axes.permutation) (originalOuterIndex plan out)
      (Fin.cast rightRank ⟨plan.axes.moved.val, by omega⟩)).val = _
    rw [rightAxis]
    rw [Heldout.IndexTransportAttempt.transpose_coordinate_value, movedOut]
  exact leftValue.symm.trans (hcoord.trans rightValue)

#print axioms Goal_proved

/-! Compiler/worker log (UTC; Lean 4.35.0; LEAN_PATH
`/tmp/space-transport-worker:/tmp/space-merged-gate-20261117`).
Elapsed wall from contract start 18:30:26 to last successful compile 18:43:53: 13m27s.
Active reasoning time and token cost were not measured. No independent review yet.

* 18:32:52.330–18:32:52.731 (0.401s), rc=1: initial direct simp left the frozen
  delinearize/linearize moved-coordinate equality (residual preserved in the
  parent-provided `actual-original-extraction-residual.log.txt`).
* 18:37:19.701–18:37:20.168 (0.467s), rc=1: first packed-prefix helper draft had
  dependent prefix-shape mismatch and unqualified `join`.
* 18:38:06.209–18:38:06.604 (0.395s), rc=1: helper orientation mismatch and
  original target still open.
* 18:38:40.963–18:38:41.400 (0.437s), rc=1: corrected index-value orientation;
  target still open.
* 18:39:31.397–18:39:32.184 (0.787s), rc=1: shape/count/cancellation route
  elaborated; packed equality and axis casts remained.
* 18:40:32.752–18:40:33.584 (0.832s), rc=1: packed-position inverse and
  permutation-index cast diagnostics.
* 18:41:04.320–18:41:05.220 (0.900s), rc=1: residual narrowed to prefix bound,
  reshape inverse, Fin value equality and final casts.
* 18:41:45.883–18:41:46.693 (0.810s), rc=1: residual narrowed further to
  prefix bound, rank-cast packed equality, permutation value and target casts.
* 18:42:46.551–18:42:47.220 (0.669s), rc=1: packed equality and prefix
  conditions resolved; residual was permutation output-axis value and target
  cast cleanup.
* 18:43:14.923–18:43:15.619 (0.696s), rc=0: exact `Goal_proved` compiled;
  axioms `[propext, Classical.choice, Quot.sound]`.
* 18:43:47.167–18:43:47.838 (0.671s), rc=0: exact proof emitted to an isolated
  temporary olean; same allowed axiom set.
* 18:43:52.971–18:43:53.281 (0.310s), rc=0: actual moved-axis integration
  compiled; same allowed axiom set.
-/
end Heldout.OriginalCoordinateProof
