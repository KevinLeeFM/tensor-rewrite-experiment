module
public import TailHeadConnection
/-! Source-specific equality of the tails after the count/moved pair. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.WorkerSuffix
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.PlanShapeSplit Heldout.RecursiveShapeSplit Heldout.PermutationRegions
  Heldout.TailHeadConnection Heldout.OriginalSplitConnection Heldout.ChunkIntervals
  TensorRewrite.Pilot.FiniteProduct TensorRewrite.Theory.Concatenation

/-- After removing the original count and moved axes, all remaining extents
agree with the replacement tail after its merged axis. The width axis is
handled by the original split product and the model's exact output-shape rule.
This statement is source-specific and assumes only `Conditions`. -/
theorem suffix_extents {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank}
    (plan : Conditions shape inner outer) :
    ∀ k : Fin (rank - plan.axes.moved.val - 1),
      tailShape (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
          (cutShape plan.axes inner)
          ⟨2 + k.val, by have hm := moved_before_split plan.axes; omega⟩ =
      tailShape (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
          (replacementCutShape plan (fun _ => (0 : Nat)))
          ⟨1 + k.val, by have hm := moved_before_split plan.axes; omega⟩ := by
  intro k
  rw [tail_axis, tail_axis]
  simp only [cutShape, replacementCutShape]
  let d : Fin (rank + 1) := Fin.cast (cut_rank plan.axes)
    ⟨plan.axes.moved.val + (2 + k.val), by
      have hm := moved_before_split plan.axes
      have hs := plan.axes.split.isLt
      omega⟩
  let e : Fin rank := Fin.cast (replacement_cut_rank plan.axes)
    ⟨plan.axes.moved.val + (1 + k.val), by
      have hm := moved_before_split plan.axes
      have hs := plan.axes.split.isLt
      omega⟩
  have hd : d.val = plan.axes.moved.val + 2 + k.val := by simp [d]; omega
  have he : e.val = plan.axes.moved.val + 1 + k.val := by simp [e]; omega
  have hde : d.val = e.val + 1 := by omega
  simp only [transposedShape]
  change inner (plan.axes.permutation.outputToInput d) =
    (concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct (fun _ => (0 : Nat)))
        (concatAxis plan.axes))) e
  by_cases hwidth : d.val = plan.axes.split.val + 1
  · have hdEq : d = plan.axes.split.succ := Fin.ext hwidth
    have hinner := plan.innerWidthAxis
    have hindex : e.val = plan.axes.split.val := by omega
    have heq : e = plan.axes.split := Fin.ext hindex
    have hp : plan.axes.permutation.outputToInput plan.axes.split.succ = plan.axes.split.succ :=
      Heldout.PermutationCoordinate.width_axis_fixed plan.axes
    have haxis : plan.axes.permutation.outputToInput d = plan.axes.split.succ := by
      rw [hdEq, hp]
    rw [haxis]
    rw [heq]
    have hchunk : (concatFrame shape plan.axes plan.width).shape
        (total (chunkBlocks (splitFrame shape plan.axes.split)
          (framedInput shape plan.axes.split plan.splitProduct (fun _ => (0 : Nat)))
          (concatAxis plan.axes))) plan.axes.split = plan.width := by
      have hsplitConcat : plan.axes.split ≠ concatAxis plan.axes :=
        Ne.symm (concat_distinct plan.axes)
      rw [chunk_output_shape]
      simp [hsplitConcat]
    exact hinner.trans hchunk.symm
  · have hafterMoved : plan.axes.moved.val < d.val := by omega
    have hneq : d ≠ plan.axes.moved := by intro h; have := congrArg Fin.val h; omega
    have horig : inner (plan.axes.permutation.outputToInput d) = shape e := by
      by_cases hbefore : d.val < plan.axes.split.val + 1
      · have hp := between_moved_split plan.axes d hafterMoved (by omega)
        have hinnerAxis : plan.axes.permutation.outputToInput d = e.castSucc := by
          apply Fin.ext
          simp only [Fin.val_castSucc]
          omega
        rw [hinnerAxis]
        exact plan.prefixAxes e (by omega)
      · have hafter : plan.axes.split.val < d.val := by omega
        have hp := after_split plan.axes d hafter
        have hinnerAxis : plan.axes.permutation.outputToInput d = e.succ := by
          apply Fin.ext
          simp only [Fin.val_succ]
          omega
        rw [hinnerAxis]
        exact plan.suffixAxes e (by omega)
    have hreplacement :
        (concatFrame shape plan.axes plan.width).shape
          (total (chunkBlocks (splitFrame shape plan.axes.split)
            (framedInput shape plan.axes.split plan.splitProduct (fun _ => (0 : Nat)))
            (concatAxis plan.axes))) e = shape e := by
      have hconcat : e ≠ concatAxis plan.axes := by
        intro heq; have := congrArg Fin.val heq; simp [e, concatAxis] at this
      have hsplit : e ≠ plan.axes.split := by
        intro heq; have := congrArg Fin.val heq; simp [e] at this; omega
      rw [chunk_output_shape]
      simp [hconcat, hsplit]
    simpa [transposedShape, hreplacement] using horig

#print axioms suffix_extents
end Heldout.WorkerSuffix
