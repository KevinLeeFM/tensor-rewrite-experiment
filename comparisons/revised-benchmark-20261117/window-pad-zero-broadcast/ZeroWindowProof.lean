import ZeroWindowSpec
namespace RevisedBenchmark.PadZ
def address (c : Bool) : Fin (width c) :=
  ⟨if c then 0 else 1,by cases c <;> decide⟩
theorem refuted (c h : Bool) : ¬ Claim c h := by
  intro ok
  have mismatch : old c h (fun _ => true) (address c) 1 1 ≠
      broadcasted c h (fun _ => true) (address c) := by cases c <;> cases h <;> decide
  exact mismatch (ok _ _ 1 1)
#print axioms refuted
end RevisedBenchmark.PadZ
