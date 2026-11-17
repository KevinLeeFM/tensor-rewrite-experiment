module
public import RowMajorSplitIntegration
public import OriginalCoordinateIntegration
public import PermutationRegions
@[expose] public section
set_option autoImplicit false
namespace Heldout.OtherAxisProof
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
  TensorRewrite.Pilot.FiniteProduct Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.IndexTransportAttempt Heldout.OriginalSplitConnection Heldout.RecursiveShapeSplit
  Heldout.WorkerIndexJoin Heldout.PlanShapeSplit Heldout.TailHeadConnection
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


theorem original_prefix {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer)
    (i : Fin rank) (hi : i.val < plan.axes.split.val) :
    (originalIndex plan out i).val =
      (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
        (originalOuterIndex plan out) i.castSucc).val := by
  let m := plan.axes.split.val
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
  let targetAxis : Fin m := ⟨i.val, by dsimp [m]; exact hi⟩
  have hcoord := prefixIndices targetAxis
  rw [preIndex_axis, preIndex_axis] at hcoord
  have leftAxis : Fin.cast leftRank ⟨targetAxis.val, by omega⟩ = i := by
    apply Fin.ext
    rfl
  have rightAxis : Fin.cast rightRank ⟨targetAxis.val, by omega⟩ = i.castSucc := by
    apply Fin.ext
    rfl
  change (originalIndex plan out (Fin.cast leftRank ⟨targetAxis.val, by omega⟩)).val =
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank ⟨targetAxis.val, by omega⟩)).val at hcoord
  rw [leftAxis, rightAxis] at hcoord
  exact hcoord
theorem original_suffix {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer)
    (j : Fin rank) (hj : plan.axes.split.val < j.val) :
    (originalIndex plan out j).val =
      (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
        (originalOuterIndex plan out) j.succ).val := by
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
  have joined : join (Fin.cast lhead (li 0)) (Fin.cast (congrArg elementCount suffixEq) lpos) =
      join (join (Fin.cast rhead (ri 0)) (Fin.cast rsecond (ri (Fin.succ 0)))) rpos := by
    apply Fin.ext
    have assoc := congrArg Fin.val (Heldout.ProductAssociation.join_associate
      (Fin.cast rhead (ri 0)) (Fin.cast rsecond (ri (Fin.succ 0))) rpos)
    simpa only [Fin.val_cast] using packed.trans assoc.symm
  have col := congrArg column joined
  rw [column_join, column_join] at col
  have pos : (lpos).val = (rpos).val := by
    have v := congrArg Fin.val col
    simpa only [Fin.val_cast] using v
  let ls : Shape s := fun i => lt i.succ
  let rs : Shape s := fun i => rt i.succ.succ
  let lsi : Index ls := fun i => li i.succ
  let rsi : Index rs := fun i => ri i.succ.succ
  let trans : Index rs := fun i => Fin.cast (congrFun suffixEq i) (lsi i)
  have tr := linearize_transport suffixEq lsi
  have same : linearize rs trans = linearize rs rsi := by
    apply Fin.ext
    have v := congrArg Fin.val tr
    simpa [trans, lpos, rpos, ls, rs, lsi, rsi] using v.trans pos
  have indices : trans = rsi := by
    have e := congrArg (delinearize rs) same
    simpa only [delinearize_linearize] using e
  let i : Fin s := ⟨j.val - m - 1, by dsimp [s, m]; have h := j.isLt; omega⟩
  have hv := congrArg (fun f : Index rs => (f i).val) indices
  have hv' : (lsi i).val = (rsi i).val := by simpa [trans] using hv
  dsimp [lsi, rsi, li, ri] at hv'
  rw [tailIndex_axis, tailIndex_axis] at hv'
  have lidx : Fin.cast leftRank ⟨m + i.succ.val, by omega⟩ = j := by
    apply Fin.ext
    simp [i, m]
    omega
  have ridx : Fin.cast rightRank ⟨m + i.succ.succ.val, by omega⟩ = j.succ := by
    apply Fin.ext
    simp [i, m]
    omega
  change (originalIndex plan out (Fin.cast leftRank ⟨m + i.succ.val, by omega⟩)).val =
    (Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out) (Fin.cast rightRank ⟨m + i.succ.succ.val, by omega⟩)).val at hv'
  rw [lidx, ridx] at hv'
  exact hv'

theorem outer_prefix {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (i : Fin rank)
    (hi : i.val < plan.axes.moved.val) :
    (originalOuterIndex plan out ⟨i.val, by omega⟩).val =
      (replacementOuterIndex plan input out i).val := by
  let m := plan.axes.moved.val
  let left := preShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner)
  let right := preShape (m := m) (n := rank - m) (replacementCutShape plan input)
  let li := preIndex (m := m) (n := rank + 1 - m) (cutIndex plan.axes inner (originalOuterIndex plan out))
  let ri := preIndex (m := m) (n := rank - m) (replacementCutIndex plan input out)
  have hs : left = right := Heldout.WorkerIndexPrefix.prefix_shapes_equal plan input
  have hp : (linearize left li).val = (linearize right ri).val :=
    Heldout.TailCountIntegration.actual_prefix_packed_values_equal plan input out
  let trans : Index right := fun j => Fin.cast (congrFun hs j) (li j)
  have ht := linearize_transport hs li
  have hp' : (linearize right trans).val = (linearize right ri).val := by
    have v := congrArg Fin.val ht
    simpa [trans] using v.trans hp
  have heq : trans = ri := by
    have e := congrArg (delinearize right) (Fin.ext hp')
    simpa only [delinearize_linearize] using e
  let j : Fin m := ⟨i.val, hi⟩
  have hv := congrArg (fun f : Index right => (f j).val) heq
  have hv' : (li j).val = (ri j).val := by simpa [trans] using hv
  dsimp [li, ri] at hv'
  rw [preIndex_axis, preIndex_axis] at hv'
  change (originalOuterIndex plan out (Fin.cast (cut_rank plan.axes) ⟨j.val, by omega⟩)).val =
    (replacementOuterIndex plan input out (Fin.cast (replacement_cut_rank plan.axes) ⟨j.val, by omega⟩)).val at hv'
  have hb := moved_before_split plan.axes
  have hsbound := plan.axes.split.isLt
  have hj := j.isLt
  have l : Fin.cast (cut_rank plan.axes) ⟨j.val, by omega⟩ = (⟨i.val, by omega⟩ : Fin (rank + 1)) := by apply Fin.ext; rfl
  have r : Fin.cast (replacement_cut_rank plan.axes) ⟨j.val, by omega⟩ = i := by apply Fin.ext; rfl
  rw [l, r] at hv'
  exact hv'
theorem outer_suffix {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (j : Fin rank)
    (hj : plan.axes.moved.val < j.val) :
    (originalOuterIndex plan out ⟨j.val + 1, by omega⟩).val =
      (replacementOuterIndex plan input out j).val := by
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
  let i : Fin k := ⟨j.val - m - 1, by dsimp [k]; omega⟩
  have h := Heldout.ActualSuffixProof.Goal_proved plan input out i
  change (tailIndex (m := 2) (n := k) li i).val =
    (tailIndex (m := 1) (n := k) ri i).val at h
  rw [tailIndex_axis, tailIndex_axis] at h
  dsimp [li, ri] at h
  rw [tailIndex_axis, tailIndex_axis] at h
  have lidx : Fin.cast (cut_rank plan.axes)
      ⟨m + (Fin.cast lRank ⟨2 + i.val, by omega⟩).val, by omega⟩ = ⟨j.val + 1, by omega⟩ := by
    apply Fin.ext
    simp [i, m]
    omega
  have ridx : Fin.cast (replacement_cut_rank plan.axes)
      ⟨m + (Fin.cast rRank ⟨1 + i.val, by omega⟩).val, by omega⟩ = j := by
    apply Fin.ext
    simp [i, m]
    omega
  change (originalOuterIndex plan out (Fin.cast (cut_rank plan.axes)
      ⟨m + (Fin.cast lRank ⟨2 + i.val, by omega⟩).val, by omega⟩)).val =
    (replacementOuterIndex plan input out (Fin.cast (replacement_cut_rank plan.axes)
      ⟨m + (Fin.cast rRank ⟨1 + i.val, by omega⟩).val, by omega⟩)).val at h
  rw [lidx, ridx] at h
  exact h

theorem replacement_other {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (i : Fin rank)
    (hc : i ≠ concatAxis plan.axes) (hs : i ≠ plan.axes.split) :
    (replacementIndex plan input out i).val = (replacementOuterIndex plan input out i).val := by
  simp [replacementIndex, replacementOuterIndex, Heldout.OrderedSlices.sourceIndex,
    Heldout.SliceTransport.destinationIndex, TensorRewrite.Theory.Concatenation.Frame.withPosition,
    TensorRewrite.Theory.Concatenation.Frame.rest, splitFrame, concatFrame,
    Heldout.SliceTransport.destinationFrame, hc, hs]
  rfl

theorem before_moved {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (i : Fin rank)
    (hi : i.val < plan.axes.moved.val) :
    originalIndex plan out i = replacementIndex plan input out i := by
  have hm := moved_before_split plan.axes
  have hc : i ≠ concatAxis plan.axes := by
    intro e
    have v := congrArg Fin.val e
    simp [concatAxis] at v
    omega
  have hs : i ≠ plan.axes.split := by
    intro e
    have v := congrArg Fin.val e
    omega
  let d : Fin (rank + 1) := ⟨i.val, by have h := i.isLt; omega⟩
  have axis : plan.axes.permutation.outputToInput d = i.castSucc := by
    apply Fin.ext
    simpa [d] using Heldout.PermutationRegions.before_moved plan.axes d hi
  have inv : plan.axes.permutation.inputToOutput i.castSucc = d := by
    rw [← axis, plan.axes.permutation.input_output]
  apply Fin.ext
  rw [original_prefix plan out i (by omega), transpose_coordinate_value, inv]
  exact (outer_prefix plan input out i hi).trans (replacement_other plan input out i hc hs).symm
theorem between_moved_split {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (i : Fin rank)
    (lo : plan.axes.moved.val < i.val) (hi : i.val < plan.axes.split.val) :
    originalIndex plan out i = replacementIndex plan input out i := by
  have hc : i ≠ concatAxis plan.axes := by
    intro e
    have v := congrArg Fin.val e
    simp [concatAxis] at v
    omega
  have hs : i ≠ plan.axes.split := by
    intro e
    have v := congrArg Fin.val e
    omega
  let d : Fin (rank + 1) := ⟨i.val + 1, by have h := i.isLt; omega⟩
  have axis : plan.axes.permutation.outputToInput d = i.castSucc := by
    apply Fin.ext
    have h := Heldout.PermutationRegions.between_moved_split plan.axes d (by dsimp [d]; omega) (by dsimp [d]; omega)
    change (plan.axes.permutation.outputToInput d).val = i.val
    have hd : d.val = i.val + 1 := rfl
    omega
  have inv : plan.axes.permutation.inputToOutput i.castSucc = d := by
    rw [← axis, plan.axes.permutation.input_output]
  apply Fin.ext
  rw [original_prefix plan out i hi, transpose_coordinate_value, inv]
  exact (outer_suffix plan input out i lo).trans (replacement_other plan input out i hc hs).symm
theorem after_split {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) (i : Fin rank)
    (hi : plan.axes.split.val < i.val) :
    originalIndex plan out i = replacementIndex plan input out i := by
  have hm := moved_before_split plan.axes
  have hc : i ≠ concatAxis plan.axes := by
    intro e
    have v := congrArg Fin.val e
    simp [concatAxis] at v
    omega
  have hs : i ≠ plan.axes.split := by
    intro e
    have v := congrArg Fin.val e
    omega
  let d : Fin (rank + 1) := i.succ
  have axis : plan.axes.permutation.outputToInput d = i.succ := by
    apply Fin.ext
    have h := Heldout.PermutationRegions.after_split plan.axes d (by dsimp [d]; omega)
    change (plan.axes.permutation.outputToInput d).val = i.val + 1
    simpa [d] using h
  have inv : plan.axes.permutation.inputToOutput i.succ = d := by
    rw [← axis, plan.axes.permutation.input_output]
  apply Fin.ext
  rw [original_suffix plan out i hi, transpose_coordinate_value, inv]
  exact (outer_suffix plan input out i (by omega)).trans (replacement_other plan input out i hc hs).symm

theorem other : Heldout.RemainingAxisGoals.Other := by
  intro rank outerRank shape inner outer α plan input out i hc hs
  have hm := moved_before_split plan.axes
  have hcval : i.val ≠ plan.axes.moved.val := by
    intro e
    apply hc
    apply Fin.ext
    simpa [concatAxis] using e
  have hsval : i.val ≠ plan.axes.split.val := by
    intro e
    apply hs
    exact Fin.ext e
  by_cases h : i.val < plan.axes.moved.val
  · exact before_moved plan input out i h
  · by_cases h' : i.val < plan.axes.split.val
    · exact between_moved_split plan input out i (by omega) h'
    · exact after_split plan input out i (by omega)
#print axioms original_suffix
#print axioms after_split
#print axioms other
#print axioms between_moved_split
#print axioms before_moved
#print axioms original_prefix
#print axioms outer_prefix
end Heldout.OtherAxisProof
