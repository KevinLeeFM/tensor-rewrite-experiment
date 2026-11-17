module
public import SlicePadProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceOfPad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
private def sh (n : Nat) : Shape 1 := fun _ => n
private def xs {n : Nat} : Tensor (sh n) Nat := fun j => (j 0).val + 10
private def signed : Params (sh 4) (sh 5) := ⟨fun _ => 2, fun _ => -1, fun _ => 0, fun _ => by rfl⟩
private def a : Fin 1 → SliceShape.Axis := fun _ => ⟨3,5,1⟩
example : shifted signed a 0 = ⟨1,3,1⟩ := by decide
example : tensor signed 99 xs (fun _ => (⟨3,by decide⟩ : Fin 5)) = 11 := by decide
example : tensor signed 99 xs (fun _ => (⟨0,by decide⟩ : Fin 5)) = 99 := by decide
private def spaced : Params (sh 3) (sh 7) := ⟨fun _ => 1, fun _ => 1, fun _ => 1, fun _ => by rfl⟩
example : SliceShape.IsWellFormed 7 3 ⟨1,6,2⟩ := by decide
example : tensor spaced 99 xs (fun _ => (⟨3,by decide⟩ : Fin 7)) = 11 ∧
    tensor spaced 99 xs (fun _ => (⟨2,by decide⟩ : Fin 7)) = 99 := by decide
end RevisedBenchmark.SliceOfPad
