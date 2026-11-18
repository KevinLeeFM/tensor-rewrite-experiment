import BaseSpec
namespace RevisedBenchmark.ReduceBase
def examplePlan : Plan := ⟨1, 3, Or.inl rfl⟩
def values (_ : Nat) (c : Fin 2) : Int := if c.val = 0 then 4 else -3
theorem refuted : ¬ Goal := by
  intro h
  exact (by decide : original examplePlan values 0 ≠ replacement examplePlan values 0)
    (congrFun (h examplePlan 2 values) 0)
theorem equalProfile (p : Plan) (h : p.inputRows = p.outputRows) {n : Nat}
    (read : Nat → Fin n → Int) : original p read = replacement p read := by
  funext c
  unfold original replacement
  rw [← h]
  by_cases one : p.inputRows = 1
  · simp [one]
  · simp [one]
#print axioms refuted
#print axioms equalProfile
end RevisedBenchmark.ReduceBase
