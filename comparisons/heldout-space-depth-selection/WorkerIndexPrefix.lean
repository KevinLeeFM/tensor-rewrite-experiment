module
public import TailHeadConnection
public import WorkerIndexJoin

/-! Actual prefix frame extents and packed coordinates for the frozen plan. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.WorkerIndexPrefix
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Theory.Concatenation
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.RecursiveShapeSplit
  Heldout.PlanShapeSplit Heldout.OriginalSplitConnection Heldout.PermutationRegions
  Heldout.ChunkIntervals Heldout.SliceTransport Heldout.WorkerIndexJoin

/-- Each recursively selected prefix extent is the corresponding full-shape extent. -/
theorem pre_axis {m n : Nat} (shape : Shape (n + m)) (i : Fin m) :
    preShape (m := m) (n := n) shape i = shape ⟨i.val, by omega⟩ := by
  induction m with
  | zero => exact Fin.elim0 i
  | succ m ih =>
    refine Fin.cases ?_ (fun i => ?_) i
    · rfl
    · simpa [preShape] using ih (fun j => shape j.succ) i

/-- Before the moved axis, the actual original and replacement prefix frames
have exactly the same extents. -/
theorem prefix_shapes_equal {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank}
    {α : Type} (plan : Conditions shape inner outer) (input : Tensor shape α) :
    preShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
      (cutShape plan.axes inner) =
    preShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
      (replacementCutShape plan input) := by
  funext i
  rw [pre_axis, pre_axis]
  let d : Fin (rank + 1) := ⟨i.val, by have h := plan.axes.moved.isLt; omega⟩
  let j : Fin rank := ⟨i.val, by have h := plan.axes.moved.isLt; omega⟩
  have dval : d.val = i.val := rfl
  have jval : j.val = i.val := rfl
  have axisBefore : (plan.axes.permutation.outputToInput d).val = d.val :=
    before_moved plan.axes d (by have h := plan.axes.moved.isLt; omega)
  have mapped : plan.axes.permutation.outputToInput d = j.castSucc := by
    apply Fin.ext
    simp only [axisBefore, dval, jval, Fin.val_castSucc]
  have dcast : Fin.cast (cut_rank plan.axes) ⟨i.val, by
      have h := plan.axes.moved.isLt; omega⟩ = d := by
    apply Fin.ext
    rfl
  have jcast : ⟨i.val, (by have h := plan.axes.moved.isLt; omega : i.val < rank)⟩ = j := by
    apply Fin.ext
    rfl
  rw [show cutShape plan.axes inner ⟨i.val, by omega⟩ =
      transposedShape inner plan.axes.permutation (Fin.cast (cut_rank plan.axes)
        ⟨i.val, by have h := plan.axes.moved.isLt; omega⟩) by rfl]
  rw [show replacementCutShape plan input ⟨i.val, by omega⟩ =
      (concatFrame shape plan.axes plan.width).shape
        (total (chunkBlocks (splitFrame shape plan.axes.split)
          (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)))
        (Fin.cast (replacement_cut_rank plan.axes) ⟨i.val, by omega⟩) by rfl]
  rw [dcast, transposedShape, mapped]
  rw [plan.prefixAxes j (by have h := moved_before_split plan.axes; omega)]
  have replacementAxis : Fin.cast (replacement_cut_rank plan.axes)
      ⟨i.val, by have h := moved_before_split plan.axes; omega⟩ = j := by
    apply Fin.ext
    rfl
  rw [replacementAxis]
  have j_ne_split : j ≠ plan.axes.split := by
    intro h
    have hv := congrArg Fin.val h
    simp [j] at hv
    have hm := moved_before_split plan.axes
    have hi := i.isLt
    omega
  have j_ne_moved : j ≠ concatAxis plan.axes := by
    intro h
    have hv := congrArg Fin.val h
    simp [j, concatAxis] at hv
    have hm := moved_before_split plan.axes
    have hi := i.isLt
    omega
  simp [concatFrame, destinationFrame, splitFrame, Frame.shape, j_ne_split, j_ne_moved]

/-- Given equal tail element counts, the two actual outer packed decompositions
force equal packed coordinates in their actual prefixes. -/
theorem prefix_packed_values_equal {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer)
    (tailCount : elementCount (tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner)) =
      elementCount (tailShape (m := plan.axes.moved.val)
        (n := rank - plan.axes.moved.val) (replacementCutShape plan input))) :
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (preIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out)))).val =
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (preIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out))).val := by
  have preShapeEq := prefix_shapes_equal plan input
  have preCount : elementCount (preShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner)) =
      elementCount (preShape (m := plan.axes.moved.val)
        (n := rank - plan.axes.moved.val) (replacementCutShape plan input)) :=
    congrArg elementCount preShapeEq
  have packed := outer_packed_parts_equal plan input out
  unfold packedParts at packed
  have components := packed_component_values preCount tailCount
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (preIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out))))
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (preIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out)))
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (tailIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out))))
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (tailIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out))) packed
  exact components.1

#print axioms pre_axis
#print axioms prefix_shapes_equal
#print axioms prefix_packed_values_equal
end Heldout.WorkerIndexPrefix
