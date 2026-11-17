module
public import TensorRewrite.Pilot.Permutation
public import TensorRewrite.Pilot.DynamicIndex
/-! Logical DynamicSlice/Transpose at arbitrary permutation; statement only. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.DynamicTranspose
open TensorRewrite.Pilot TensorRewrite.Pilot.DynamicIndex

/-- Output shape of the actual permutation. -/
def transposedShape {rank : Nat} (s : Shape rank) (p : AxisPermutation rank) : Shape rank :=
  fun axis => s (p.outputToInput axis)

/-- Original starts and widths for slicing the untransposed operand. -/
def sourceSizes {rank : Nat} (sizes : Shape rank) (p : AxisPermutation rank) : Shape rank :=
  fun axis => sizes (p.inputToOutput axis)
def sourceStarts {rank : Nat} (starts : Fin rank → Int) (p : AxisPermutation rank) : Fin rank → Int :=
  fun axis => starts (p.inputToOutput axis)

/-- Valid output slice widths imply validity for the permuted input axes. -/
theorem sourceFits {rank : Nat} (s sizes : Shape rank) (p : AxisPermutation rank)
    (fits : ∀ i, sizes i ≤ transposedShape s p i) : ∀ i, sourceSizes sizes p i ≤ s i := by
  intro i
  simpa [sourceSizes, transposedShape, p.output_input] using fits (p.inputToOutput i)

/-- Actual logical DynamicSlice with clamped mathematical Int starts. -/
def slice {rank : Nat} {s size : Shape rank} {α : Type}
    (starts : Fin rank → Int) (fits : ∀ i, size i ≤ s i) (input : Tensor s α) : Tensor size α :=
  Tensor.reindex (dynamicSliceIndex starts fits) input

/-- Complete arbitrary-permutation logical graph equality; no target proof supplied. -/
def Goal : Prop :=
  ∀ (rank : Nat) (s : Shape rank) (p : AxisPermutation rank) (sizes : Shape rank)
    (starts : Fin rank → Int) (fits : ∀ i, sizes i ≤ transposedShape s p i)
    (α : Type) (input : Tensor s α),
    slice starts fits (Tensor.transpose p (fun i => by simp [transposedShape, p.output_input]) input) =
      Tensor.transpose p (fun _ => rfl) (slice (sourceStarts starts p) (sourceFits s sizes p fits) input)

#print Goal
#print axioms Goal
end Heldout.DynamicTranspose
