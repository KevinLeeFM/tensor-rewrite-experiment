module
public import NegativeProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.NegativePad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
private def one (n : Nat) : Shape 1 := fun _ => n
private def mixed : Params (one 3) (one 6) :=
  ⟨fun _ => -1, fun _ => 2, fun _ => 1, fun _ => by rfl⟩

example : middle mixed 0 = 7 ∧ crop mixed 0 = ⟨1, 7, 1⟩ := by decide
example : SliceShape.IsWellFormed (middle mixed 0) 6 (crop mixed 0) := by decide
example : ¬ SliceShape.IsWellFormed (middle mixed 0) 6 ⟨0,7,1⟩ := by decide
private def leftPad : Params (one 3) (one 4) :=
  ⟨fun _ => 2, fun _ => -1, fun _ => 0, fun _ => by rfl⟩
example : crop leftPad 0 = ⟨0,4,1⟩ := by decide
private def both : Params (one 2) (one 0) :=
  ⟨fun _ => -1, fun _ => -1, fun _ => 0, fun _ => by rfl⟩
example : crop both 0 = ⟨1,1,1⟩ ∧ SliceShape.IsWellFormed 2 0 (crop both 0) := by decide
example : Goal := correct
end RevisedBenchmark.NegativePad
