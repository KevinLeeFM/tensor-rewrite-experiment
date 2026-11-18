import StrengthSpec
namespace RevisedBenchmark.DotStrength
def x (o k : Fin 2) : Fin 64 := if o = 1 then 1 else if k = 0 then 33 else 2
def w (o k : Fin 2) : Fin 64 := if o = 1 then 1 else if k = 0 then 63 else 1

theorem refuted (f : Free) : ¬ Goal f := by
  intro h
  let o : Fin (outer f) := ⟨0, by cases f <;> decide⟩
  have bad : dot f x w 0 ≠ reduced f x w 0 := by cases f <;> decide
  exact bad (h x w o)
#print axioms refuted
end RevisedBenchmark.DotStrength
