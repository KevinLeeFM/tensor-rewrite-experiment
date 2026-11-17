module
public import WorkerSuffix
public import WorkerIndexPrefix
/-! Bounded integration: equal tail element counts from merged head and suffix extents. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.TailCountIntegration
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex Heldout.SpaceDepthCandidate
  Heldout.SourceFrame Heldout.PlanShapeSplit Heldout.RecursiveShapeSplit
  Heldout.OriginalSplitConnection Heldout.TailHeadConnection Heldout.WorkerSuffix
  Heldout.ChunkIntervals TensorRewrite.Theory.Concatenation

/-- Merging two leading extents preserves the total count when the suffix matches. -/
theorem merge_count {k : Nat} (left : Shape (k + 2)) (right : Shape (k + 1))
    (head : right 0 = left 0 * left 1)
    (suffix : ∀ i : Fin k, left i.succ.succ = right i.succ) :
    elementCount left = elementCount right := by
  have sameTail : (fun i : Fin k => left i.succ.succ) = (fun i => right i.succ) := by
    funext i
    exact suffix i
  simp only [elementCount]
  rw [head, sameTail]
  exact (Nat.mul_assoc _ _ _).symm

/-- Rank-casting shape axes preserves its element count. -/
theorem rank_cast_count {r s : Nat} (equal : r = s) (shape : Shape s) :
    elementCount (fun i : Fin r => shape (Fin.cast equal i)) = elementCount shape := by
  cases equal
  rfl

/-- The two actual plan tail counts agree, including empty shapes. -/
theorem plan_tail_count {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer) (input : Tensor shape α) :
    elementCount (tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner)) =
    elementCount (tailShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
      (replacementCutShape plan input)) := by
  let m := plan.axes.moved.val
  let k := rank - m - 1
  have before := moved_before_split plan.axes
  have bound := plan.axes.split.isLt
  have leftRank : k + 2 = rank + 1 - m := by dsimp [k, m]; omega
  have rightRank : k + 1 = rank - m := by dsimp [k, m]; omega
  let left : Shape (k + 2) := fun i => tailShape (m := m) (n := rank + 1 - m)
    (cutShape plan.axes inner) (Fin.cast leftRank i)
  let right : Shape (k + 1) := fun i => tailShape (m := m) (n := rank - m)
    (replacementCutShape plan input) (Fin.cast rightRank i)
  have head : right 0 = left 0 * left 1 := by
    have r0 : Fin.cast rightRank (0 : Fin (k + 1)) = ⟨0, by dsimp [k, m]; omega⟩ := by
      apply Fin.ext; rfl
    have l0 : Fin.cast leftRank (0 : Fin (k + 2)) = ⟨0, by dsimp [k, m]; omega⟩ := by
      apply Fin.ext; rfl
    have l1 : Fin.cast leftRank (1 : Fin (k + 2)) = ⟨1, by dsimp [k, m]; omega⟩ := by
      apply Fin.ext; rfl
    simp only [left, right]
    rw [r0, l0, l1]
    exact tail_extents_merge plan input
  have suffix : ∀ i : Fin k, left i.succ.succ = right i.succ := by
    intro i
    have li : Fin.cast leftRank i.succ.succ = ⟨2 + i.val, by dsimp [k, m] at *; omega⟩ := by
      apply Fin.ext; simp; omega
    have ri : Fin.cast rightRank i.succ = ⟨1 + i.val, by dsimp [k, m] at *; omega⟩ := by
      apply Fin.ext; simp; omega
    simp only [left, right]
    rw [li, ri]
    have hshape : replacementCutShape plan input =
        replacementCutShape plan (fun _ => (0 : Nat)) := by
      funext j
      simp only [replacementCutShape]
      rw [chunkBlocks_total, chunkBlocks_total]
    rw [hshape]
    exact suffix_extents plan i
  have h := merge_count left right head suffix
  have hL := rank_cast_count leftRank (tailShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner))
  have hR := rank_cast_count rightRank (tailShape (m := m) (n := rank - m) (replacementCutShape plan input))
  exact hL.symm.trans (h.trans hR)

/-- The actual plan determines equal packed prefix coordinates without a new premise. -/
theorem actual_prefix_packed_values_equal {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer)
 :
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (preIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out)))).val =
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (preIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out))).val :=
  Heldout.WorkerIndexPrefix.prefix_packed_values_equal plan input out (plan_tail_count plan input)

#print axioms actual_prefix_packed_values_equal
#print axioms plan_tail_count
#print axioms merge_count
end Heldout.TailCountIntegration
