import LogSpec
namespace RevisedBenchmark.LogSqrt
theorem refuted : ¬ Goal := by
  intro law
  have h := law 1 16777215 (by decide) (by decide +kernel) (by decide +kernel)
  exact (by decide : 0 ≠ 16777215) h
#print axioms refuted
end RevisedBenchmark.LogSqrt
