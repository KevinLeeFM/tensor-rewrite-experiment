module
public import ChunkIntervals
public import ShapeBridge
public import TensorRewrite.Pilot.Permutation

/-! Derived source-frame shape and axis witnesses. These are not a rewrite theorem. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.SourceFrame
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation
  Heldout.ShapeBridge Heldout.SliceTransport Heldout.OrderedSlices Heldout.ChunkIntervals

/-- The source input shape viewed as a frame at its split axis. -/
def splitFrame {rank : Nat} (shape : Shape rank) (split : Fin rank) : Frame rank :=
  ⟨shape, split⟩

/-- A checked split-product equality derives equality of the original and framed shapes. -/
theorem source_shape {rank count width : Nat} (shape : Shape rank) (split : Fin rank)
    (product : shape split = count * width) :
    (splitFrame shape split).shape (count * width) = shape := by
  funext i
  by_cases h : i = split
  · subst i
    simp [splitFrame, Frame.shape, product]
  · simp [splitFrame, Frame.shape, h]

/-- Transport input coordinates through the derived shape equality. -/
def framedInput {rank count width : Nat} {α : Type} (shape : Shape rank)
    (split : Fin rank) (product : shape split = count * width) (input : Tensor shape α) :
    Tensor ((splitFrame shape split).shape (count * width)) α :=
  fun index => input (fun i => Fin.cast (congrFun (source_shape shape split product) i) (index i))

/-- The derived input cast preserves every coordinate's natural value. -/
theorem framedInput_coordinate {rank count width : Nat} (shape : Shape rank)
    (split : Fin rank) (product : shape split = count * width)
    (index : Index ((splitFrame shape split).shape (count * width))) (i : Fin rank) :
    (Fin.cast (congrFun (source_shape shape split product) i) (index i)).val = (index i).val := rfl

/-- The source's permutation loop conditions, expressed over bounded axes. -/
structure AxisConditions (rank : Nat) where
  split : Fin rank
  moved : Fin (rank + 1)
  permutation : AxisPermutation (rank + 1)
  selected : permutation.outputToInput moved = split.castSucc
  different : moved ≠ split.castSucc
  offset : ∀ d, d ≠ moved →
    (permutation.outputToInput d).val = d.val - (if d.val > moved.val then 1 else 0) +
      (if d.val > split.val then 1 else 0)

/-- The actual permutation is injective by its existing inverse law. -/
theorem permutation_injective {rank : Nat} (p : AxisPermutation rank) :
    ∀ a b, p.outputToInput a = p.outputToInput b → a = b := by
  intro a b same
  have h := congrArg p.inputToOutput same
  simpa only [p.input_output] using h

/-- The checked source permutation positions the moved axis before the split. -/
theorem moved_before_split {rank : Nat} (plan : AxisConditions rank) :
    plan.moved.val < plan.split.val := by
  exact moved_axis_before_split plan.permutation.outputToInput plan.split.castSucc plan.moved
    (permutation_injective plan.permutation) plan.selected plan.different plan.offset

/-- The moved source axis is consequently a legal input-rank concatenation axis. -/
def concatAxis {rank : Nat} (plan : AxisConditions rank) : Fin rank :=
  ⟨plan.moved.val, by have h := moved_before_split plan; have b := plan.split.isLt; omega⟩

/-- Slices use a different split axis and concatenation axis. -/
theorem concat_distinct {rank : Nat} (plan : AxisConditions rank) :
    concatAxis plan ≠ plan.split := by
  intro same
  have h := congrArg Fin.val same
  have before := moved_before_split plan
  simp [concatAxis] at h
  omega

/-- The concat frame derives from the checked input shape and the legal moved axis. -/
def concatFrame {rank : Nat} (shape : Shape rank) (plan : AxisConditions rank)
    (width : Nat) : Frame rank :=
  destinationFrame (splitFrame shape plan.split) width (concatAxis plan)

/-- At a distinct concat axis the frame retains the original input extent. -/
theorem concat_extent {rank : Nat} (shape : Shape rank) (plan : AxisConditions rank)
    (width : Nat) :
    (splitFrame shape plan.split).shape width (concatAxis plan) = shape (concatAxis plan) := by
  simp [splitFrame, Frame.shape, concat_distinct plan]

/-- The source-derived chunk output has the exact two-axis updated shape. -/
theorem chunk_output_shape {rank count width : Nat} {α : Type} (shape : Shape rank)
    (plan : AxisConditions rank) (product : shape plan.split = count * width)
    (input : Tensor shape α) (i : Fin rank) :
    (concatFrame shape plan width).shape
        (total (chunkBlocks (splitFrame shape plan.split) (framedInput shape plan.split product input)
          (concatAxis plan))) i =
      if i = concatAxis plan then count * shape (concatAxis plan)
      else if i = plan.split then width else shape i := by
  rw [chunkBlocks_total]
  simp [concatFrame, destinationFrame, splitFrame, Frame.shape, concat_distinct plan]

#print axioms source_shape
#print axioms framedInput_coordinate
#print axioms permutation_injective
#print axioms moved_before_split
#print axioms concat_distinct
#print axioms concat_extent
#print axioms chunk_output_shape
end Heldout.SourceFrame
