import EmptyFoldSpec
set_option autoImplicit false
namespace RevisedBenchmark.EmptyFold

theorem witness :
    declared (geometry 0 1) = [2,2] ∧ inferred (geometry 0 1) = [3,2] := by decide

theorem refuted : ¬ Goal := by
  intro all
  have eq := all 0 1
  rw [witness.1, witness.2] at eq
  exact (by decide : ([2,2] : List Nat) ≠ [3,2]) eq

#print axioms witness
#print axioms refuted
end RevisedBenchmark.EmptyFold
