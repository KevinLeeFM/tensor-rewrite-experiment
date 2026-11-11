module

public import TensorRewrite.Theory.ReductionWindowAlgebra

/-! Padding-law counterexamples in the declared ordered window model. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionWindow

open Pilot

/-- Concrete padded axis used only in the counterexample certificates. -/
def paddedAxis (input kernel : Nat) : Convolution.Axis where
  inputExtent := input
  kernelExtent := kernel
  stride := 1
  baseDilation := 1
  kernelDilation := 1
  paddingLow := 1
  paddingHigh := if input = 0 then 0 else 1
  reversed := false
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide

/-- A unit window with one padded output and no valid input coordinate. -/
def emptyPadded : Plan 1 := ⟨fun _ => paddedAxis 0 1⟩
/-- A three-position window with two invalid positions around one valid input. -/
def threeSamples : Plan 1 := ⟨fun _ => paddedAxis 1 3⟩

/-- The sole output coordinate of the padded-empty certificate. -/
def emptyOutput : Index emptyPadded.outputShape :=
  fun _ => ⟨0, by decide +revert⟩

/-- The sole output coordinate of the three-sample certificate. -/
def threeOutput : Index threeSamples.outputShape :=
  fun _ => ⟨0, by decide +revert⟩

/-- Dropping the padding fixed-point premise changes a unit window from two to one. -/
theorem padding_fixed_refuted :
    reduce emptyPadded Nat.add 1 1 (Tensor.constant 7) emptyOutput = 2 ∧
      gatherMap emptyPadded 1 (Nat.add 1) (Tensor.constant 7) emptyOutput = 1 ∧
      (2 : Nat) ≠ 1 := by decide

/-- Skipping invalid samples changes a padded nonneutral additive window. -/
theorem padding_skip_refuted :
    values threeSamples 3 (Tensor.constant (2 : Nat)) threeOutput = [3, 2, 3] ∧
      reduce threeSamples Nat.add 3 3 (Tensor.constant 2) threeOutput = 11 ∧
      ([2] : List Nat).foldl Nat.add 3 = 5 ∧ (11 : Nat) ≠ 5 := by decide

end TensorRewrite.Theory.ReductionWindow
