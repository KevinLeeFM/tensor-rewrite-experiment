module
public import PlanShapeSplit
public import TensorRewrite.Pilot.Reshape
public import IndexTransportAttempt
/-! Relate the actual original outer reshape index to the plan's moved-axis split. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.OriginalSplitConnection
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
  TensorRewrite.Pilot.FiniteProduct Heldout.SourceFrame Heldout.SpaceDepthCandidate
  Heldout.PlanShapeSplit Heldout.RecursiveShapeSplit Heldout.ElementCount
  Heldout.ChunkIntervals TensorRewrite.Theory.Concatenation

/-- Reindexing every axis through a rank equality preserves row-major position. -/
theorem rank_cast_packed {r s : Nat} (equal : r = s) (shape : Shape s) (index : Index shape) :
    (linearize (fun i : Fin r => shape (Fin.cast equal i))
      (fun i => index (Fin.cast equal i))).val = (linearize shape index).val := by
  cases equal
  rfl

/-- The actual index produced by the original graph's outer reshape. -/
def originalOuterIndex {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer) :
    Index (transposedShape inner plan.axes.permutation) :=
  reshapeIndex (transposedShape inner plan.axes.permutation) outer
    ((permute_count inner plan.axes.permutation).trans (plan.innerCount.symm.trans plan.outerCount)) out

/-- The original outer reshape carries the output's packed position. -/
theorem original_outer_position {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer) :
    (linearize (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)).val =
      (linearize outer out).val :=
  Heldout.IndexTransportAttempt.reshape_linear_value _ _ _ out

/-- The actual index read by the replacement concatenation's outer reshape. -/
def replacementOuterIndex {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    Index ((concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)))) :=
  reshapeIndex _ outer (chunk_count plan input) out

/-- Both actual outer reshapes retain exactly the same output linear position. -/
theorem outer_positions_equal {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    (linearize (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)).val =
    (linearize ((concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes))))
      (replacementOuterIndex plan input out)).val := by
  rw [original_outer_position]
  exact (Heldout.IndexTransportAttempt.reshape_linear_value _ _ _ out).symm

/-- Rank transport does not change the original outer reshape's packed position. -/
theorem original_rank_cast {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer) :
    (linearize (cutShape plan.axes inner) (cutIndex plan.axes inner (originalOuterIndex plan out))).val =
      (linearize (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)).val :=
  rank_cast_packed (cut_rank plan.axes) (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)

/-- The original outer reshape's actual packed index splits at the plan's moved axis. -/
theorem original_outer_split {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer) :
    (linearize (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)).val =
      (join (linearize (preShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
        (preIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val) (cutIndex plan.axes inner (originalOuterIndex plan out))))
        (linearize (tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
        (tailIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val) (cutIndex plan.axes inner (originalOuterIndex plan out))))).val := by
  rw [← original_rank_cast plan out]
  exact plan_index_split plan.axes inner (originalOuterIndex plan out)

/-- The value reconstructed from the actual prefix and tail of a full index. -/
def packedParts {m n : Nat} (shape : Shape (n + m)) (index : Index shape) : Nat :=
  (join (linearize (preShape (m := m) (n := n) shape) (preIndex (m := m) (n := n) index))
    (linearize (tailShape (m := m) (n := n) shape) (tailIndex (m := m) (n := n) index))).val

/-- The same moved axis is a legal cut in the replacement rank. -/
theorem replacement_cut_rank {rank : Nat} (axes : AxisConditions rank) :
    (rank - axes.moved.val) + axes.moved.val = rank := by
  apply Nat.sub_add_cancel
  have h := moved_before_split axes
  have bound := axes.split.isLt
  omega

/-- The actual concatenation shape and index, at the replacement's cut rank. -/
def replacementCutShape {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) : Shape ((rank - plan.axes.moved.val) + plan.axes.moved.val) :=
  fun i => (concatFrame shape plan.axes plan.width).shape
    (total (chunkBlocks (splitFrame shape plan.axes.split)
      (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)))
    (Fin.cast (replacement_cut_rank plan.axes) i)

def replacementCutIndex {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) : Index (replacementCutShape plan input) :=
  fun i => replacementOuterIndex plan input out (Fin.cast (replacement_cut_rank plan.axes) i)

/-- Both real outer-reshape coordinates have equal packed prefix/tail decompositions. -/
theorem outer_packed_parts_equal {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) :
    packedParts (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) (cutIndex plan.axes inner (originalOuterIndex plan out)) =
    packedParts (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
      (replacementCutShape plan input) (replacementCutIndex plan input out) := by
  calc
    _ = (linearize (cutShape plan.axes inner)
      (cutIndex plan.axes inner (originalOuterIndex plan out))).val :=
        (full_linearize_split _).symm
    _ = (linearize (transposedShape inner plan.axes.permutation) (originalOuterIndex plan out)).val :=
      original_rank_cast plan out
    _ = (linearize ((concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes))))
      (replacementOuterIndex plan input out)).val := outer_positions_equal plan input out
    _ = (linearize (replacementCutShape plan input) (replacementCutIndex plan input out)).val :=
      (rank_cast_packed (replacement_cut_rank plan.axes) _ _).symm
    _ = _ := full_linearize_split _

#print axioms outer_packed_parts_equal
#print axioms outer_positions_equal
#print axioms original_outer_position
#print axioms rank_cast_packed
#print axioms original_rank_cast
#print axioms original_outer_split
end Heldout.OriginalSplitConnection
