module
public import SplitStrategyTarget
public import ProductAssociation
public import TensorRewrite.Pilot.FiniteProductLemmas
@[expose] public section
set_option autoImplicit false
namespace Heldout.RowMajorSplitProof
open TensorRewrite.Pilot.FiniteProduct Heldout.ProductAssociation

/-- Recover the merged coordinate from equal row-major positions, with an
arbitrary admitted trailing packed coordinate. -/
theorem merged_head {a b s : Nat} (merged : Fin (a * b)) (x : Fin a) (y : Fin b)
    (tail tail' : Fin s)
    (same : (join merged tail).val = (join x (join y tail')).val) :
    merged.val = x.val * b + y.val := by
  have h : join merged tail = join (join x y) tail' := by
    apply Fin.ext
    have assoc := congrArg Fin.val (join_associate x y tail')
    simpa only [Fin.val_cast] using same.trans assoc.symm
  have hh := congrArg row h
  rw [row_join, row_join] at hh
  exact congrArg Fin.val hh

#print axioms merged_head


open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.IndexTransportAttempt
  Heldout.OriginalSplitConnection Heldout.RecursiveShapeSplit Heldout.WorkerIndexJoin

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

theorem target_attempt : Heldout.SplitStrategyTarget.Goal := by
  intro rank outerRank shape inner outer plan out
  let m := plan.axes.split.val
  have splitBound := plan.axes.split.isLt
  have mLe : m ≤ rank := by dsimp [m]; omega
  let s := rank - m - 1
  have leftRank : (s + 1) + m = rank := by dsimp [s, m]; omega
  have rightRank : (s + 2) + m = rank + 1 := by dsimp [s, m]; omega
  let leftShape : Shape ((s + 1) + m) := fun i => shape (Fin.cast leftRank i)
  let rightShape : Shape ((s + 2) + m) := fun i => inner (Fin.cast rightRank i)
  let leftIndex : Index leftShape := fun i => originalIndex plan out (Fin.cast leftRank i)
  let rightIndex : Index rightShape := fun i =>
    Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank i)
  have prefixEq : preShape (m := m) (n := s + 1) leftShape =
      preShape (m := m) (n := s + 2) rightShape := by
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
      have hi : i.val < plan.axes.split.val := by simp [m]
      exact hi)).symm
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
      elementCount (preShape (m := m) (n := s + 1) leftShape) *
          elementCount (tailShape (m := m) (n := s + 1) leftShape) =
      elementCount (preShape (m := m) (n := s + 2) rightShape) *
          elementCount (tailShape (m := m) (n := s + 2) rightShape) := by
    calc
      _ = elementCount leftShape := leftSplit.symm
      _ = elementCount rightShape := sameCount
      _ = _ := rightSplit
  have prefixPositive : 0 < elementCount (preShape (m := m) (n := s + 1) leftShape) :=
    Nat.zero_lt_of_lt (linearize _ (preIndex (m := m) (n := s + 1) leftIndex)).isLt
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
  have parts := packed_component_values prefixCount tailsEqual
    (linearize _ (preIndex (m := m) (n := s + 1) leftIndex))
    (linearize _ (preIndex (m := m) (n := s + 2) rightIndex))
    (linearize _ (tailIndex (m := m) (n := s + 1) leftIndex))
    (linearize _ (tailIndex (m := m) (n := s + 2) rightIndex)) (by
      exact (full_linearize_split leftIndex).symm.trans
        (packedEqual.trans (full_linearize_split rightIndex)))
  let lt := tailShape (m := m) (n := s + 1) leftShape
  let rt := tailShape (m := m) (n := s + 2) rightShape
  have suffixEq : (fun i : Fin s => lt i.succ) = (fun i : Fin s => rt i.succ.succ) := by
    funext i
    dsimp [lt, rt]
    rw [Heldout.TailHeadConnection.tail_axis, Heldout.TailHeadConnection.tail_axis]
    let j : Fin rank := ⟨m + 1 + i.val, by dsimp [s, m] at *; omega⟩
    have l : Fin.cast leftRank ⟨m + i.succ.val, by omega⟩ = j := by apply Fin.ext; simp [j]; omega
    have r : Fin.cast rightRank ⟨m + i.succ.succ.val, by omega⟩ = j.succ := by apply Fin.ext; simp [j]; omega
    change shape (Fin.cast leftRank ⟨m + i.succ.val, by omega⟩) =
      inner (Fin.cast rightRank ⟨m + i.succ.succ.val, by omega⟩)
    rw [l, r]
    exact (plan.suffixAxes j (by dsimp [j, m]; omega)).symm
  have lhead : lt 0 = plan.count * plan.width := by
    dsimp [lt]
    rw [Heldout.TailHeadConnection.tail_axis]
    have idx : Fin.cast leftRank ⟨m + (0 : Fin (s+1)).val, by omega⟩ = plan.axes.split := by
      apply Fin.ext
      simp [m]
    change shape (Fin.cast leftRank ⟨m + (0 : Fin (s+1)).val, by omega⟩) = _
    rw [idx, plan.splitProduct]
  have rhead : rt 0 = plan.count := by
    dsimp [rt]
    rw [Heldout.TailHeadConnection.tail_axis]
    have idx : Fin.cast rightRank ⟨m + (0 : Fin (s+2)).val, by omega⟩ = plan.axes.split.castSucc := by
      apply Fin.ext
      simp [m]
    change inner (Fin.cast rightRank ⟨m + (0 : Fin (s+2)).val, by omega⟩) = _
    rw [idx, plan.innerCountAxis]
  have rsecond : rt (Fin.succ 0) = plan.width := by
    dsimp [rt]
    rw [Heldout.TailHeadConnection.tail_axis]
    have idx : Fin.cast rightRank ⟨m + (Fin.succ (0 : Fin (s+1))).val, by omega⟩ = plan.axes.split.succ := by
      apply Fin.ext
      simp [m]
    change inner (Fin.cast rightRank ⟨m + (Fin.succ (0 : Fin (s+1))).val, by omega⟩) = _
    rw [idx, plan.innerWidthAxis]
  let li := tailIndex (m := m) (n := s + 1) leftIndex
  let ri := tailIndex (m := m) (n := s + 2) rightIndex
  let lpos := linearize (fun i : Fin s => lt i.succ) (fun i => li i.succ)
  let rpos := linearize (fun i : Fin s => rt i.succ.succ) (fun i => ri i.succ.succ)
  have packed : (join (Fin.cast lhead (li 0)) (Fin.cast (congrArg elementCount suffixEq) lpos)).val =
      (join (Fin.cast rhead (ri 0)) (join (Fin.cast rsecond (ri (Fin.succ 0))) rpos)).val := by
    have h := parts.2
    change (join (li 0) lpos).val = (join (ri 0) (join (ri (Fin.succ 0)) rpos)).val at h
    simp only [FiniteProduct.join, Fin.val_cast] at h ⊢
    have rsecond' : tailShape (m := m) (n := s + 2) rightShape (Fin.succ 0) = plan.width := rsecond
    simpa only [congrArg elementCount suffixEq, rsecond'] using h
  have head := merged_head (Fin.cast lhead (li 0)) (Fin.cast rhead (ri 0))
    (Fin.cast rsecond (ri (Fin.succ 0))) (Fin.cast (congrArg elementCount suffixEq) lpos) rpos packed
  simp only [Fin.val_cast] at head
  have leftAxis : Fin.cast leftRank ⟨m + (0 : Fin (s+1)).val, by omega⟩ = plan.axes.split := by
    apply Fin.ext
    simp [m]
  have rightAxis0 : Fin.cast rightRank ⟨m + (0 : Fin (s+2)).val, by omega⟩ = plan.axes.split.castSucc := by
    apply Fin.ext
    simp [m]
  have rightAxis1 : Fin.cast rightRank ⟨m + (Fin.succ (0 : Fin (s+1))).val, by omega⟩ = plan.axes.split.succ := by
    apply Fin.ext
    simp [m]
  dsimp [li, ri] at head
  rw [tailIndex_axis, tailIndex_axis, tailIndex_axis] at head
  change (originalIndex plan out (Fin.cast leftRank ⟨m + (0 : Fin (s+1)).val, by omega⟩)).val =
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank ⟨m + (0 : Fin (s+2)).val, by omega⟩)).val * plan.width +
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank ⟨m + (Fin.succ (0 : Fin (s+1))).val, by omega⟩)).val at head
  rw [leftAxis, rightAxis0, rightAxis1] at head
  exact head

#print axioms target_attempt
end Heldout.RowMajorSplitProof
