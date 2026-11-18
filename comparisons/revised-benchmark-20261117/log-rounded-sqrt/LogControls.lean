import LogProof
namespace RevisedBenchmark.LogSqrt
example : ¬ Goal := refuted
example : rootIsOne 0 = true ∧ logRead 0 0 = true := by decide +kernel
example : logRead 1 16777214 = false ∧ logRead 1 16777216 = false := by decide +kernel
example : rootIsOne 2 = false := by decide +kernel
end RevisedBenchmark.LogSqrt
