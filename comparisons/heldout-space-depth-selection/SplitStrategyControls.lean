module
import ActualSplitFactorGoal
open TensorRewrite.Pilot TensorRewrite.Pilot.FiniteProduct Heldout.SpaceDepthCandidate
  Heldout.SourceFrame Heldout.ChunkIntervals Heldout.OriginalSplitConnection Heldout.IndexTransportAttempt
set_option autoImplicit false
namespace Heldout.SplitStrategyControls

def shape : Shape 4 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else if i.val = 2 then 6 else 2
def inner : Shape 5 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else if i.val = 2 then 2 else if i.val = 3 then 3 else 2
def outer : Shape 4 := fun i => if i.val = 0 then 6 else if i.val = 1 then 4 else if i.val = 2 then 3 else 2
def swap : Fin 5 → Fin 5 := fun i => if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i
def perm : AxisPermutation 5 where
  outputToInput := swap
  inputToOutput := swap
  output_input := by decide
  input_output := by decide
def axes : AxisConditions 4 where
  split := ⟨2, by decide⟩
  moved := ⟨1, by decide⟩
  permutation := perm
  selected := by decide
  different := by decide
  offset := by decide
def plan : Conditions shape inner outer where
  axes := axes
  count := 2
  width := 3
  innerCountAxis := by decide
  innerWidthAxis := by decide
  splitProduct := by decide
  firstMismatch := by decide
  prefixAxes := by decide
  suffixAxes := by decide
  countCap := by decide
  innerCount := by decide
  outerCount := by decide
  outerRankAtLeast := by decide
  outputShape := by decide
def input : Tensor shape Nat := fun _ => 0
def out (a : Fin 6) (b : Fin 4) (c : Fin 3) (d : Fin 2) : Index outer :=
  fun i => Fin.cases a (Fin.cases b (Fin.cases c (fun _ => d))) i

def check (o : Index outer) : Prop :=
  let source := splitFrame shape axes.split
  let axis := concatAxis axes
  let framed := framedInput shape axes.split plan.splitProduct input
  let frame := concatFrame shape axes plan.width
  let position := frame.position (replacementOuterIndex plan input o)
  let q := Fin.cast (chunkBlocks_total source framed axis) position
  (originalIndex plan o axes.split).val = (row q).val * plan.width + (replacementOuterIndex plan input o axes.split).val

example : check (out 0 0 0 0) := by unfold check; decide
example : check (out 0 3 2 1) := by unfold check; decide
example : check (out 3 3 2 1) := by unfold check; decide
example : check (out 5 0 0 0) := by unfold check; decide
example : check (out 5 3 2 1) := by unfold check; decide
def selectedRow (o : Index outer) : Nat :=
  let source := splitFrame shape axes.split
  let axis := concatAxis axes
  let framed := framedInput shape axes.split plan.splitProduct input
  let frame := concatFrame shape axes plan.width
  let q := Fin.cast (chunkBlocks_total source framed axis) (frame.position (replacementOuterIndex plan input o))
  (row q).val
def selectedPosition (o : Index outer) : Nat :=
  ((concatFrame shape axes plan.width).position (replacementOuterIndex plan input o)).val
example : check (out 1 0 0 0) := by unfold check; decide
example : selectedPosition (out 0 3 2 1) = 3 := by unfold selectedPosition; decide
example : selectedPosition (out 1 0 0 0) = 4 := by unfold selectedPosition; decide
example : selectedRow (out 0 3 2 1) = 0 := by unfold selectedRow; decide
example : selectedRow (out 1 0 0 0) = 1 := by unfold selectedRow; decide
def badShape : Shape 3 := fun i => if i.val = 2 then 4 else 2
def badInner : Shape 4 := fun _ => 2
def badOuter : Shape 3 := fun i => if i.val = 0 then 4 else 2
def swap12 : AxisPermutation 4 where
  outputToInput := fun i => if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i
  inputToOutput := fun i => if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i
  output_input := by decide
  input_output := by decide

def badAxes : AxisConditions 3 where
  split := ⟨2, by decide⟩
  moved := ⟨1, by decide⟩
  permutation := swap12
  selected := by decide
  different := by decide
  offset := by decide

def badPlan : Conditions badShape badInner badOuter where
  axes := badAxes
  count := 2
  width := 2
  innerCountAxis := by decide
  innerWidthAxis := by decide
  splitProduct := by decide
  firstMismatch := by decide
  prefixAxes := by decide
  suffixAxes := by decide
  countCap := by decide
  innerCount := by decide
  outerCount := by decide
  outerRankAtLeast := by decide
  outputShape := by decide

def badInput : Tensor badShape Bool := fun _ => false
def badOut : Index badOuter := fun i =>
  ⟨if i.val = 0 then 2 else 1, by
    by_cases h : i.val = 0 <;> simp [badOuter, h] <;> decide⟩

example : (originalIndex badPlan badOut badAxes.split).val =
    (row (Fin.cast (chunkBlocks_total (splitFrame badShape badAxes.split)
      (framedInput badShape badAxes.split badPlan.splitProduct badInput) (concatAxis badAxes))
      ((concatFrame badShape badAxes badPlan.width).position (replacementOuterIndex badPlan badInput badOut)))).val *
    badPlan.width + (replacementOuterIndex badPlan badInput badOut badAxes.split).val := by decide
def innerIndex (o : Index outer) : Index inner :=
  Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
    (originalOuterIndex plan o)
def originalSplitPacked (o : Index outer) : Prop :=
  (originalIndex plan o axes.split).val =
    (innerIndex o axes.split.castSucc).val * plan.width + (innerIndex o axes.split.succ).val
example : originalSplitPacked (out 0 0 0 0) := by unfold originalSplitPacked; decide
example : originalSplitPacked (out 0 3 2 1) := by unfold originalSplitPacked; decide
example : originalSplitPacked (out 1 0 0 0) := by unfold originalSplitPacked; decide
example : originalSplitPacked (out 3 3 2 1) := by unfold originalSplitPacked; decide
example : originalSplitPacked (out 5 3 2 1) := by unfold originalSplitPacked; decide
end Heldout.SplitStrategyControls
