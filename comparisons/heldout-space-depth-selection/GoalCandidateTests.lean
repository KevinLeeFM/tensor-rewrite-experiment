module
import GoalCandidate
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Theory.Concatenation
  Heldout.SourceFrame Heldout.ChunkIntervals Heldout.SpaceDepthCandidate
set_option autoImplicit false
namespace Heldout.SpaceDepthCandidate.Tests

def swap : Fin 4 → Fin 4 := fun i =>
  if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i

def perm : AxisPermutation 4 where
  outputToInput := swap
  inputToOutput := swap
  output_input := by decide
  input_output := by decide

def plan : AxisConditions 3 where
  split := ⟨2, by decide⟩
  moved := ⟨1, by decide⟩
  permutation := perm
  selected := by decide
  different := by decide
  offset := by decide

def shape : Shape 3 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else 6
def zeroShape : Shape 3 := fun i => if i.val = 0 then 0 else if i.val = 1 then 4 else 6

def inner : Shape 4 := fun i =>
  if i.val = 0 then 3 else if i.val = 1 then 4 else if i.val = 2 then 2 else 3

def outer : Shape 3 := fun i => if i.val = 0 then 6 else if i.val = 1 then 4 else 3

/-- A source-compatible nonempty mathematical plan, not a native visitor run. -/
def nonemptyPlan : Conditions shape inner outer where
  axes := plan
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

def linearInput : Tensor shape Nat := fun i =>
  24 * (i ⟨0, by decide⟩).val + 6 * (i ⟨1, by decide⟩).val + (i ⟨2, by decide⟩).val

def outIndex : Index outer := fun i => ⟨if i.val = 0 then 1 else 0,
  (show ∀ i : Fin 3, (if i.val = 0 then 1 else 0) < outer i by decide) i⟩

/-- The original and candidate replacement produce a nontrivial concrete value. -/
example : original nonemptyPlan linearInput outIndex = 3 := by decide
example : replacement nonemptyPlan linearInput outIndex = 3 := by decide

/-- An invalid outer extent cannot satisfy the checked source output guard. -/
example : ¬ ((3 : Nat) = 3 * 2) := by decide
/-- The source-compatible branch can have another zero extent. -/
def zeroInner : Shape 4 := fun i =>
  if i.val = 0 then 0 else if i.val = 1 then 4 else if i.val = 2 then 2 else 3
def zeroOuter : Shape 3 := fun i => if i.val = 0 then 0 else if i.val = 1 then 4 else 3

def emptyPlan : Conditions zeroShape zeroInner zeroOuter where
  axes := plan
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

example : ¬ Nonempty (Index zeroOuter) := by
  intro ⟨index⟩
  exact Fin.elim0 (index ⟨0, by decide⟩)
end Heldout.SpaceDepthCandidate.Tests
namespace Heldout.SpaceDepthCandidate.Tests

/-- Wrong concat axis produces the same outer shape but different row-major data. -/
def wrongAxis : Fin 3 := ⟨0, by decide⟩
def wrongFrame := Heldout.SliceTransport.destinationFrame (splitFrame shape plan.split) 3 wrongAxis
def wrongInput := framedInput (count := 2) (width := 3) shape plan.split (by decide) linearInput
def wrongIndex : Index (wrongFrame.shape (total (chunkBlocks (splitFrame shape plan.split)
    wrongInput wrongAxis))) := fun i => ⟨if i.val = 0 then 1 else 0,
      (show ∀ i : Fin 3, (if i.val = 0 then 1 else 0) <
        (wrongFrame.shape (total (chunkBlocks (splitFrame shape plan.split) wrongInput wrongAxis))) i
        by decide) i⟩
example : concatenate (chunkBlocks (splitFrame shape plan.split) wrongInput wrongAxis) wrongIndex = 24 := by decide
example : original nonemptyPlan linearInput outIndex ≠
    concatenate (chunkBlocks (splitFrame shape plan.split) wrongInput wrongAxis) wrongIndex := by decide

/-- One chunk is admitted without requiring a non-unit chunk count. -/
def oneShape : Shape 3 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else 3
def oneInner : Shape 4 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else if i.val = 2 then 1 else 3

def onePlan : Conditions oneShape oneInner oneShape where
  axes := plan
  count := 1
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
end Heldout.SpaceDepthCandidate.Tests
namespace Heldout.SpaceDepthCandidate.Tests
/-- Zero-width chunks remain represented while another axis has positive size. -/
def widthZeroShape : Shape 3 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else 0
def widthZeroInner : Shape 4 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else if i.val = 2 then 2 else 0
def widthZeroOuter : Shape 3 := fun i => if i.val = 0 then 6 else if i.val = 1 then 4 else 0

def widthZeroPlan : Conditions widthZeroShape widthZeroInner widthZeroOuter where
  axes := plan
  count := 2
  width := 0
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
end Heldout.SpaceDepthCandidate.Tests
