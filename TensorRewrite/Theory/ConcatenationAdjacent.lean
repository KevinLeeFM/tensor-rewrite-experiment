module

public import TensorRewrite.Theory.ConcatenationMerge

/-! Adjacent actual Slice operands merge at any shared positive selected stride, retaining
arbitrary common legal cropping/strides on all other axes and arbitrary outer Concat operands.
-/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Merge two actual Slice operands, including every shape component and all data values. -/
theorem adjacent_slices_pair {rank extent firstLength secondLength : Nat}
    {inputFrame : Frame rank} {α : Type} (crop : Crop inputFrame)
    (input : Tensor (inputFrame.shape extent) α) (first second : SliceShape.Axis)
    (firstValid : SliceShape.IsWellFormed extent firstLength first)
    (secondValid : SliceShape.IsWellFormed extent secondLength second)
    (sameStride : second.stride = first.stride)
    (adjacent : second.start = first.start + (firstLength : Int) * first.stride) :
    pack [crop.blockWith input first firstLength firstValid,
        crop.blockWith input second secondLength secondValid] =
      crop.blockWith input (mergeAxis first second) (firstLength + secondLength)
        (merged_axis_valid first second firstValid secondValid sameStride adjacent) := by
  refine block_eq_of_values _ _ (by simp [pack, total, Crop.blockWith]) ?_
  funext index
  change Index (crop.outputFrame.shape (firstLength + secondLength)) at index
  refine (cast_concatenate_value (frame := crop.outputFrame)
    (outputExtent := firstLength + secondLength)
    [crop.blockWith input first firstLength firstValid,
      crop.blockWith input second secondLength secondValid]
    (by simp [total, Crop.blockWith]) index).trans ?_
  by_cases before : (crop.outputFrame.position index).val < firstLength
  · have beforeBlock : (crop.outputFrame.position index).val <
        (crop.blockWith input first firstLength firstValid).extent := before
    rw [readAt, dite_eq_left beforeBlock]
    apply congrArg input
    funext axis
    apply Fin.ext
    by_cases selected : axis = inputFrame.axis
    · subst axis
      simp [Crop.sliceWith, Crop.axesWith, IndexMaps.sliceIndex, Frame.withPosition,
        Frame.position, Crop.outputFrame, Fin.cast, mergeAxis]
    · simp [Crop.sliceWith, Crop.axesWith, IndexMaps.sliceIndex,
        Frame.withPosition, Frame.rest, Crop.outputFrame, Fin.cast, selected, mergeAxis]
  · have tailBound : (crop.outputFrame.position index).val - firstLength < secondLength := by
      have bound := (crop.outputFrame.position index).isLt
      change (crop.outputFrame.position index).val < firstLength + secondLength at bound
      omega
    have afterBlock : ¬ (crop.outputFrame.position index).val <
        (crop.blockWith input first firstLength firstValid).extent := before
    have tailBlock : (crop.outputFrame.position index).val -
        (crop.blockWith input first firstLength firstValid).extent <
          (crop.blockWith input second secondLength secondValid).extent := tailBound
    rw [readAt, dite_eq_right afterBlock, readAt, dite_eq_left tailBlock]
    apply congrArg input
    funext axis
    apply Fin.ext
    by_cases selected : axis = inputFrame.axis
    · subst axis
      have coordinate := adjacent_coordinate first second sameStride adjacent
        (crop.outputFrame.position index).val (by omega)
      simpa [Crop.blockWith, Crop.sliceWith, Crop.axesWith, IndexMaps.sliceIndex,
        Frame.withPosition, Frame.rest, Frame.position, Crop.outputFrame, Fin.cast, mergeAxis] using
          congrArg Int.toNat coordinate
    · simp [Crop.sliceWith, Crop.axesWith, IndexMaps.sliceIndex,
        Frame.withPosition, Frame.rest, Crop.outputFrame, Fin.cast, selected, mergeAxis]

/-- Merge adjacent actual Slices inside an arbitrary ordered concatenation context. -/
theorem adjacent_slices_context {rank extent firstLength secondLength : Nat}
    {inputFrame : Frame rank} {α : Type} (crop : Crop inputFrame)
    (input : Tensor (inputFrame.shape extent) α) (first second : SliceShape.Axis)
    (firstValid : SliceShape.IsWellFormed extent firstLength first)
    (secondValid : SliceShape.IsWellFormed extent secondLength second)
    (sameStride : second.stride = first.stride)
    (adjacent : second.start = first.start + (firstLength : Int) * first.stride)
    (leading trailing : List (Block crop.outputFrame α)) :
    pack (leading ++ ([crop.blockWith input first firstLength firstValid,
        crop.blockWith input second secondLength secondValid] ++ trailing)) =
      pack (leading ++ (crop.blockWith input (mergeAxis first second) (firstLength + secondLength)
        (merged_axis_valid first second firstValid secondValid sameStride adjacent) ::
          trailing)) := by
  exact (pack_group_context leading _ trailing).trans
    (congrArg (fun block => pack (leading ++ (block :: trailing)))
      (adjacent_slices_pair crop input first second firstValid secondValid sameStride adjacent))

/-- Every finite run of actual guarded adjacent-Slice replacements preserves complete values. -/
theorem slice_merge_run {rank extent : Nat} {inputFrame : Frame rank} {α : Type}
    {crop : Crop inputFrame} {input : Tensor (inputFrame.shape extent) α}
    {first last : List (Block crop.outputFrame α)} (run : SliceMergeRun crop input first last) :
    pack first = pack last := by
  induction run with
  | refl _ => rfl
  | cons step _ ih =>
    cases step with
    | merge first second firstValid secondValid sameStride adjacent leading trailing =>
      exact (adjacent_slices_context crop input first second firstValid secondValid
        sameStride adjacent leading trailing).trans ih

end TensorRewrite.Theory.Concatenation
