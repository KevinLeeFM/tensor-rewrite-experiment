import NamedProof
set_option maxRecDepth 10000
set_option maxHeartbeats 1500000
namespace RevisedBenchmark.NamedMaximum
example : ¬ Goal .erf := erf_refuted
example : rounds .erf 7 1 215 = false ∧ rounds .erf 23 1 14138174 = false := by decide +kernel
example : rounds .erf 23 1 14138173 = true ∧ rounds .erf 23 0 0 = true ∧ max 14138173 0 = 14138173 := by decide +kernel
example : ¬ Goal .logistic := logistic_refuted
example : rounds .logistic 7 1 186 = false ∧ rounds .logistic 23 1 12265129 = false := by decide +kernel
example : rounds .logistic 23 1 12265128 = true ∧ rounds .logistic 23 0 8388608 = true ∧ max 12265128 8388608 = 12265128 := by decide +kernel
example : ¬ Goal .tanh := tanh_refuted
example : rounds .tanh 7 1 194 = false ∧ rounds .tanh 23 1 12777431 = false := by decide +kernel
example : rounds .tanh 23 1 12777430 = true ∧ rounds .tanh 23 0 0 = true ∧ max 12777430 0 = 12777430 := by decide +kernel
end RevisedBenchmark.NamedMaximum
