import CountSpec
namespace RevisedBenchmark.CollectiveCount

theorem refuted : (¬ All) ∧ (¬ Scatter) := by
  constructor
  · intro h
    have bad := h 5 4194305 0
    exact (by decide : reduceAt (g := 5) (fun _ (_ : Fin 2) => 4194305) 0 ≠
      folded 5 4194305) bad
  · intro h
    have bad := h 5 4194305 2 4 1
    exact (by decide : reduceAt (g := 5) (fun _ (_ : Fin 12) => 4194305)
      (Exchange.slot (4 : Fin 6) (1 : Fin 2)) ≠ folded 5 4194305) bad
#print axioms refuted
end RevisedBenchmark.CollectiveCount
