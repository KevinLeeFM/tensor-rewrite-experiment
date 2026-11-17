module
import SourceFrame
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation Heldout.SourceFrame Heldout.ChunkIntervals
set_option autoImplicit false
namespace Heldout.SourceFrame.Tests

/-- Swap axes one and two of an inner rank-four shape. -/
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
def input : Tensor shape Nat := fun i =>
  100 * (i ⟨0, by decide⟩).val + 10 * (i ⟨1, by decide⟩).val + (i ⟨2, by decide⟩).val

def zeroShape : Shape 3 := fun i => if i.val = 0 then 0 else if i.val = 1 then 4 else 6
def zeroInput : Tensor zeroShape Nat := fun _ => 0

/-- The selected moved dimension becomes legal input axis one. -/
example : (concatAxis plan).val = 1 := by decide
example : concatAxis plan ≠ plan.split := concat_distinct plan
/-- The framed source tensor and resulting chunk frame retain actual dimensions. -/
example : ((splitFrame shape plan.split).shape (2 * 3)) ⟨2, by decide⟩ = 6 := by decide
example : (concatFrame shape plan 3).shape
    (total (chunkBlocks (splitFrame shape plan.split)
      (framedInput (count := 2) (width := 3) shape plan.split (by decide) input) (concatAxis plan))) ⟨0, by decide⟩ = 3 := by decide
example : (concatFrame shape plan 3).shape
    (total (chunkBlocks (splitFrame shape plan.split)
      (framedInput (count := 2) (width := 3) shape plan.split (by decide) input) (concatAxis plan))) ⟨1, by decide⟩ = 8 := by decide
example : (concatFrame shape plan 3).shape
    (total (chunkBlocks (splitFrame shape plan.split)
      (framedInput (count := 2) (width := 3) shape plan.split (by decide) input) (concatAxis plan))) ⟨2, by decide⟩ = 3 := by decide
/-- Zero on a different axis remains zero rather than being excluded. -/
example : (concatFrame zeroShape plan 3).shape
    (total (chunkBlocks (splitFrame zeroShape plan.split)
      (framedInput (count := 2) (width := 3) zeroShape plan.split (by decide) zeroInput) (concatAxis plan))) ⟨0, by decide⟩ = 0 := by decide
/-- A wrong product cannot establish the cast's required source premise. -/
example : ¬ (shape plan.split = 2 * 4) := by decide
/-- Moving the selected axis to itself violates the checked source condition. -/
example : ¬ (perm.outputToInput ⟨2, by decide⟩ = (⟨2, by decide⟩ : Fin 3).castSucc) := by decide
end Heldout.SourceFrame.Tests
namespace Heldout.SourceFrame.Tests
/-- A single chunk retains the original concatenation-axis extent. -/
example : (concatFrame shape plan 6).shape
    (total (chunkBlocks (splitFrame shape plan.split)
      (framedInput (count := 1) (width := 6) shape plan.split (by decide) input)
      (concatAxis plan))) ⟨1, by decide⟩ = 4 := by decide
/-- A zero-width split may coexist with a positive chunk count and another live axis. -/
def zeroWidthShape : Shape 3 := fun i => if i.val = 0 then 3 else if i.val = 1 then 4 else 0
def zeroWidthInput : Tensor zeroWidthShape Nat := fun _ => 0
example : (concatFrame zeroWidthShape plan 0).shape
    (total (chunkBlocks (splitFrame zeroWidthShape plan.split)
      (framedInput (count := 2) (width := 0) zeroWidthShape plan.split (by decide) zeroWidthInput)
      (concatAxis plan))) ⟨2, by decide⟩ = 0 := by decide
example : (concatFrame zeroWidthShape plan 0).shape
    (total (chunkBlocks (splitFrame zeroWidthShape plan.split)
      (framedInput (count := 2) (width := 0) zeroWidthShape plan.split (by decide) zeroWidthInput)
      (concatAxis plan))) ⟨1, by decide⟩ = 8 := by decide
end Heldout.SourceFrame.Tests
