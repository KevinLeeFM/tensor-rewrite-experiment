module
import Spec
open TensorRewrite.Pilot Heldout.TransposeBroadcast
set_option autoImplicit false
namespace Heldout.TransposeBroadcast.Tests

def swap12 (i : Fin 3) : Fin 3 :=
  if i.val = 1 then ⟨2, by decide⟩ else if i.val = 2 then ⟨1, by decide⟩ else i

def perm : AxisPermutation 3 where
  outputToInput := swap12
  inputToOutput := swap12
  output_input := by decide
  input_output := by decide

def smallShape : Shape 1 := fun _ => 3
def middle : Shape 3 := fun i => if i.val = 0 then 2 else if i.val = 1 then 3 else 4
def axes : Fin 1 → Fin 3 := fun _ => ⟨1, by decide⟩
theorem conditions : Conditions smallShape middle perm axes where
  extents := by decide
  originalOrdered := by intro i j h; have hi := i.isLt; have hj := j.isLt; omega
  replacementOrdered := by intro i j h; have hi := i.isLt; have hj := j.isLt; omega

def input : Tensor smallShape Nat := fun i => (i 0).val
def out : Index (outputShape middle perm) := fun i =>
  ⟨if i.val = 2 then 1 else 0,
    (show ∀ i : Fin 3, (if i.val = 2 then 1 else 0) < outputShape middle perm i by decide) i⟩

/-- This valid nonempty input witnesses that the case is not vacuous. -/
example : Tensor.transpose perm (fun i => by simp [outputShape, perm.output_input])
    (broadcast axes conditions.extents input) out = 1 := by decide
example : (@broadcast 1 3 smallShape (outputShape middle perm) Nat (movedAxes perm axes)
    (fun i => (conditions.extents i).trans (congrArg middle (perm.output_input (axes i))).symm)
    input) out = 1 := by decide
/-- On equal extents the incorrect old-axis broadcast is well typed and yields a wrong value. -/
def cube : Shape 3 := fun _ => 3
theorem cubeConditions : Conditions smallShape cube perm axes where
  extents := by decide
  originalOrdered := by intro i j h; have hi := i.isLt; have hj := j.isLt; omega
  replacementOrdered := by intro i j h; have hi := i.isLt; have hj := j.isLt; omega

def cubeOut : Index (outputShape cube perm) := fun i =>
  ⟨if i.val = 2 then 1 else 0,
    (show ∀ i : Fin 3, (if i.val = 2 then 1 else 0) < outputShape cube perm i by decide) i⟩
theorem wrongExtents : ∀ i, smallShape i = outputShape cube perm (axes i) := by decide
example : Tensor.transpose perm (fun i => by simp [outputShape, perm.output_input])
    (broadcast axes cubeConditions.extents input) cubeOut = 1 := by decide
example : (@broadcast 1 3 smallShape (outputShape cube perm) Nat axes wrongExtents input) cubeOut = 0 := by decide
example : Tensor.transpose perm (fun i => by simp [outputShape, perm.output_input])
    (broadcast axes cubeConditions.extents input) cubeOut ≠
    (@broadcast 1 3 smallShape (outputShape cube perm) Nat axes wrongExtents input) cubeOut := by decide


/-- False replacement is well typed but must be rejected at this witness. -/
example : Tensor.transpose perm (fun i => by simp [outputShape, perm.output_input])
    (broadcast axes cubeConditions.extents input) cubeOut =
    (@broadcast 1 3 smallShape (outputShape cube perm) Nat axes wrongExtents input) cubeOut := by decide
end Heldout.TransposeBroadcast.Tests
