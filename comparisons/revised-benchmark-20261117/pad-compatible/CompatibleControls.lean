module
public import CompatibleProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.CompatiblePad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
private def shape : Shape 2 := Fin.cases 1 (fun _ => 3)
private def mixed : Params shape shape where
  low := fun _ => 0
  high := fun _ => 0
  interior := Fin.cases 4 (fun _ => 0)
  shape := Fin.cases (by rfl) (fun _ => by rfl)
example : mixed.interior 0 = 4 ∧ mixed.interior 1 = 0 := by decide
example (xs : Tensor shape Nat) : tensor mixed 4 xs = xs := correct mixed (fun _ => ⟨rfl,rfl⟩) _ _
private def two : Shape 1 := fun _ => 2
private def shifted : Params two two := ⟨fun _ => 1, fun _ => -1, fun _ => 0, fun _ => by rfl⟩
private def origin : Index two := fun _ => ⟨0, by change 0 < 2; decide⟩
example : tensor shifted 99 (fun _ => 7) origin ≠ 7 := by decide
example {s : Shape 0} (p : Params s s) (xs : Tensor s Bool) : tensor p false xs = xs :=
  correct p (fun d => d.elim0) false xs
end RevisedBenchmark.CompatiblePad
