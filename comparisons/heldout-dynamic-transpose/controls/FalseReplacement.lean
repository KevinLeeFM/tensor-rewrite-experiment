module
import Spec
open TensorRewrite.Pilot Heldout.DynamicTranspose
set_option autoImplicit false
namespace Heldout.DynamicTranspose.Tests

def swap12 (i : Fin 3) : Fin 3 :=
  if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i
def perm : AxisPermutation 3 where
  outputToInput := swap12
  inputToOutput := swap12
  output_input := by decide
  input_output := by decide

def shape : Shape 3 := fun i => if i.val = 0 then 2 else if i.val = 1 then 3 else 4
def sizes : Shape 3 := fun i => if i.val = 0 then 2 else if i.val = 1 then 2 else 1
def starts : Fin 3 → Int := fun i => if i.val = 0 then -1 else if i.val = 1 then 1 else 99
theorem fits : ∀ i, sizes i ≤ transposedShape shape perm i := by decide

def input : Tensor shape Nat := fun i => 100 * (i ⟨0, by decide⟩).val +
  10 * (i ⟨1, by decide⟩).val + (i ⟨2, by decide⟩).val
def out : Index sizes := fun i => ⟨if i.val = 0 then 1 else 0,
  (show ∀ i : Fin 3, (if i.val = 0 then 1 else 0) < sizes i by decide) i⟩

/-- Actual nonidentity permutation and clamped starts give the same nonempty value. -/
example : slice starts fits (Tensor.transpose perm (fun i => by simp [transposedShape, perm.output_input]) input) out = 121 := by decide
example : Tensor.transpose perm (fun _ => rfl) (slice (sourceStarts starts perm) (sourceFits shape sizes perm fits) input) out = 121 := by decide
/-- Leaving starts unpermuted is well typed but yields a different result. -/
example : Tensor.transpose perm (fun _ => rfl) (slice starts (sourceFits shape sizes perm fits) input) out = 112 := by decide
example : slice starts fits (Tensor.transpose perm (fun i => by simp [transposedShape, perm.output_input]) input) out ≠
  Tensor.transpose perm (fun _ => rfl) (slice starts (sourceFits shape sizes perm fits) input) out := by decide

/-- Zero input extents and zero widths remain legal, with empty output domains. -/
def emptyShape : Shape 3 := fun i => if i.val = 0 then 0 else if i.val = 1 then 3 else 4
def emptySizes : Shape 3 := fun i => if i.val = 0 then 0 else 1
theorem emptyFits : ∀ i, emptySizes i ≤ transposedShape emptyShape perm i := by decide
example : ¬ Nonempty (Index emptySizes) := by intro ⟨i⟩; exact Fin.elim0 (i ⟨0, by decide⟩)
/-- Direct empty-output graph equality, for arbitrary input values on the empty source. -/
example (x : Tensor emptyShape Nat) :
    slice starts emptyFits (Tensor.transpose perm (fun i => by simp [transposedShape, perm.output_input]) x) =
      Tensor.transpose perm (fun _ => rfl) (slice (sourceStarts starts perm) (sourceFits emptyShape emptySizes perm emptyFits) x) := by
  funext i
  exact Fin.elim0 (i ⟨0, by decide⟩)

/-- Scalar rank has one empty coordinate and retains its input value. -/
def scalarShape : Shape 0 := fun i => Fin.elim0 i
def scalarStarts : Fin 0 → Int := fun i => Fin.elim0 i
theorem scalarFits : ∀ i, scalarShape i ≤ transposedShape scalarShape (AxisPermutation.identity 0) i := fun i => Fin.elim0 i
def scalarInput : Tensor scalarShape Nat := fun _ => 42
def scalarOut : Index scalarShape := fun i => Fin.elim0 i
example : slice scalarStarts scalarFits (Tensor.transpose (AxisPermutation.identity 0)
    (fun i => by simp [transposedShape, AxisPermutation.identity]) scalarInput) scalarOut = 42 := by decide
example : Tensor.transpose (AxisPermutation.identity 0) (fun _ => rfl)
    (slice (sourceStarts scalarStarts (AxisPermutation.identity 0))
      (sourceFits scalarShape scalarShape (AxisPermutation.identity 0) scalarFits) scalarInput) scalarOut = 42 := by decide
/-- Well-typed unpermuted-start replacement is false at the nonidentity witness. -/
example : slice starts fits (Tensor.transpose perm (fun i => by simp [transposedShape, perm.output_input]) input) out =
    Tensor.transpose perm (fun _ => rfl) (slice starts (sourceFits shape sizes perm fits) input) out := by decide
end Heldout.DynamicTranspose.Tests
