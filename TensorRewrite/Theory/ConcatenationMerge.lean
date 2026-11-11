module

public import TensorRewrite.Theory.ConcatenationGraphLemmas

/-! Finite guarded merge runs, specified by the actual two-Slice graph transformation. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- One real adjacent-Slice replacement, with raw attributes and arbitrary outer operands. -/
inductive SliceMergeStep {rank extent : Nat} {inputFrame : Frame rank} {α : Type}
    (crop : Crop inputFrame) (input : Tensor (inputFrame.shape extent) α) :
    List (Block crop.outputFrame α) → List (Block crop.outputFrame α) → Prop where
  /-- Replace exactly two guarded adjacent Slices by their computed merged Slice. -/
  | merge {firstLength secondLength : Nat} (first second : SliceShape.Axis)
      (firstValid : SliceShape.IsWellFormed extent firstLength first)
      (secondValid : SliceShape.IsWellFormed extent secondLength second)
      (sameStride : second.stride = first.stride)
      (adjacent : second.start = first.start + (firstLength : Int) * first.stride)
      (leading trailing : List (Block crop.outputFrame α)) :
      SliceMergeStep crop input
        (leading ++ ([crop.blockWith input first firstLength firstValid,
          crop.blockWith input second secondLength secondValid] ++ trailing))
        (leading ++ (crop.blockWith input (mergeAxis first second) (firstLength + secondLength)
          (merged_axis_valid first second firstValid secondValid sameStride adjacent) :: trailing))

/-- Any finite number of concrete guarded merges; no equality premise is used. -/
inductive SliceMergeRun {rank extent : Nat} {inputFrame : Frame rank} {α : Type}
    (crop : Crop inputFrame) (input : Tensor (inputFrame.shape extent) α) :
    List (Block crop.outputFrame α) → List (Block crop.outputFrame α) → Prop where
  /-- An empty run retains the original operands. -/
  | refl (blocks : List (Block crop.outputFrame α)) : SliceMergeRun crop input blocks blocks
  /-- Execute one actual merge, followed by the remaining finite run. -/
  | cons {first middle last : List (Block crop.outputFrame α)}
      (step : SliceMergeStep crop input first middle)
      (rest : SliceMergeRun crop input middle last) : SliceMergeRun crop input first last

end TensorRewrite.Theory.Concatenation
