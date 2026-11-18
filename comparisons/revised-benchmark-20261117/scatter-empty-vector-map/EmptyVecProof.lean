import EmptyVecSpec
namespace RevisedBenchmark.EmptyVecMap
def noLanes {n : Nat} (_ : Fin n) : Fin 0 → Int := Fin.elim0
def base (_ : Fin 2) : Word := 0
def updates (i : Fin 2) : Word := if i = 0 then 3 else 5
theorem refuted : ¬ Goal := by
  intro h
  exact (by decide : scatter base updates noLanes 1 ≠ replacement base updates 1)
    (congrFun (h 2 (by decide) base updates noLanes) 1)
#print axioms refuted
end RevisedBenchmark.EmptyVecMap
