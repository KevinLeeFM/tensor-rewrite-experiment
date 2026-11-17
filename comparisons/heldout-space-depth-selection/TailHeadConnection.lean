module
public import OriginalSplitConnection
public import PermutationRegions
/-! Head extents of the original and replacement cut tails. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.TailHeadConnection
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Theory.Concatenation
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.PlanShapeSplit
  Heldout.RecursiveShapeSplit Heldout.OriginalSplitConnection Heldout.ChunkIntervals
  TensorRewrite.Pilot.FiniteProduct

/-- Dropping a prefix places the axis at the cut at the head of the tail. -/
theorem tail_head {m n : Nat} (shape : Shape ((n + 1) + m)) :
    tailShape (m := m) (n := n + 1) shape 0 = shape ⟨m, by omega⟩ := by
  induction m with
  | zero => rfl
  | succ m ih =>
    change tailShape (m := m) (n := n + 1) (fun i => shape i.succ) 0 = _
    simpa using ih (fun i => shape i.succ)

/-- Each tail axis is the corresponding full axis after the prefix. -/
theorem tail_axis {m n : Nat} (shape : Shape (n + m)) (i : Fin n) :
    tailShape (m := m) (n := n) shape i = shape ⟨m + i.val, by omega⟩ := by
  induction m with
  | zero => simp [tailShape]
  | succ m ih =>
    change tailShape (m := m) (n := n) (fun i => shape i.succ) i = _
    simpa [Nat.add_comm, Nat.add_left_comm, Nat.add_assoc] using ih (fun i => shape i.succ)

/-- The first original tail extent is exactly the plan's split count. -/
theorem original_tail_count {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) :
    tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) ⟨0, by have h := plan.axes.moved.isLt; omega⟩ = plan.count := by
  rw [tail_axis]
  change inner (plan.axes.permutation.outputToInput
    (Fin.cast (cut_rank plan.axes) ⟨plan.axes.moved.val + 0, _⟩)) = plan.count
  have axis : Fin.cast (cut_rank plan.axes) ⟨plan.axes.moved.val + 0, by
      have h := plan.axes.moved.isLt; omega⟩ = plan.axes.moved := by
    apply Fin.ext
    simp
  rw [axis, plan.axes.selected, plan.innerCountAxis]

/-- The first replacement tail extent merges count with the moved input extent. -/
theorem replacement_tail_merged {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer) (input : Tensor shape α) :
    tailShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
      (replacementCutShape plan input) ⟨0, by
        have h := moved_before_split plan.axes
        have _bound := plan.axes.split.isLt
        omega⟩ = plan.count * shape (concatAxis plan.axes) := by
  rw [tail_axis]
  change (concatFrame shape plan.axes plan.width).shape
    (total (chunkBlocks (splitFrame shape plan.axes.split)
      (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)))
    (Fin.cast (replacement_cut_rank plan.axes) ⟨plan.axes.moved.val + 0, _⟩) = _
  have axis : Fin.cast (replacement_cut_rank plan.axes) ⟨plan.axes.moved.val + 0, by
      have h := moved_before_split plan.axes; have _bound := plan.axes.split.isLt; omega⟩ = concatAxis plan.axes := by
    apply Fin.ext
    simp [concatAxis]
  rw [axis, chunk_output_shape]
  simp

/-- Immediately after the count, the original tail retains the moved input extent. -/
theorem original_tail_moved {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) :
    tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) ⟨1, by
        have h := moved_before_split plan.axes
        have _bound := plan.axes.split.isLt
        omega⟩ = shape (concatAxis plan.axes) := by
  rw [tail_axis]
  change inner (plan.axes.permutation.outputToInput
    (Fin.cast (cut_rank plan.axes) ⟨plan.axes.moved.val + 1, _⟩)) = _
  have nextAxis : Fin.cast (cut_rank plan.axes) ⟨plan.axes.moved.val + 1, by
      have h := moved_before_split plan.axes; have _bound := plan.axes.split.isLt; omega⟩ =
      (concatAxis plan.axes).succ := by
    apply Fin.ext
    simp [concatAxis]
  rw [nextAxis]
  have between := Heldout.PermutationRegions.between_moved_split plan.axes (concatAxis plan.axes).succ
    (by simp [concatAxis]) (by have h := moved_before_split plan.axes; simp [concatAxis]; omega)
  have axis : plan.axes.permutation.outputToInput (concatAxis plan.axes).succ =
      (concatAxis plan.axes).castSucc := by
    apply Fin.ext
    simp only [Fin.val_succ, concatAxis] at between
    simp only [Fin.val_castSucc, concatAxis]
    omega
  rw [axis]
  apply plan.prefixAxes
  exact moved_before_split plan.axes

/-- The replacement tail's first extent is the product of the first two original extents. -/
theorem tail_extents_merge {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer) (input : Tensor shape α) :
    tailShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
      (replacementCutShape plan input) ⟨0, by
        have h := moved_before_split plan.axes; have _bound := plan.axes.split.isLt; omega⟩ =
    tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) ⟨0, by have h := plan.axes.moved.isLt; omega⟩ *
    tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) ⟨1, by
        have h := moved_before_split plan.axes; have _bound := plan.axes.split.isLt; omega⟩ := by
  rw [original_tail_count, original_tail_moved, replacement_tail_merged]

/-- The reviewed chunk selector uses quotient and remainder of the actual output axis. -/
theorem selected_chunk_coordinate {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    let source := splitFrame shape plan.axes.split
    let axis := concatAxis plan.axes
    let framed := framedInput shape plan.axes.split plan.splitProduct input
    let frame := concatFrame shape plan.axes plan.width
    let position := frame.position (replacementOuterIndex plan input out)
    let q := Fin.cast (chunkBlocks_total source framed axis) position
    (row q).val = position.val / shape axis ∧ (column q).val = position.val % shape axis := by
  constructor
  · change _ / (splitFrame shape plan.axes.split).shape plan.width (concatAxis plan.axes) = _
    simp only [Fin.val_cast]
    rw [concat_extent]
  · change _ % (splitFrame shape plan.axes.split).shape plan.width (concatAxis plan.axes) = _
    simp only [Fin.val_cast]
    rw [concat_extent]

#print axioms selected_chunk_coordinate
#print axioms tail_extents_merge
#print axioms original_tail_moved
#print axioms replacement_tail_merged
#print axioms original_tail_count
#print axioms tail_axis
#print axioms tail_head
end Heldout.TailHeadConnection
