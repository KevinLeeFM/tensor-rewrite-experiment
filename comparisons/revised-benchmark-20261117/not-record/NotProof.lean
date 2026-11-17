import NotRecord
set_option autoImplicit false
namespace RevisedBenchmark.NotRecord
open TensorRewrite.Pilot Tensor
theorem verified : Obligation := fun _ => ⟨Boolean.not_not, fun _ => Bitwise.not_not⟩
example : Obligation := verified
#print axioms verified

private def two : Shape 1 := fun _ => 2
private def sample : Tensor two (BitVec 8) := fun i => if (i 0).val = 0 then 128 else 3
example : map (fun z => ~~~z) sample (fun _ => (0 : Fin 2)) ≠ sample (fun _ => (0 : Fin 2)) := by decide
example : sample (fun _ => (0 : Fin 2)) ≠ sample (fun _ => (1 : Fin 2)) := by decide
example (x : Tensor (fun _ : Fin 0 => 0) Bool) : map Bool.not (map Bool.not x) = x :=
  (verified _).1 x
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  rintro ⟨i⟩
  exact Fin.elim0 (i 0)
end RevisedBenchmark.NotRecord
