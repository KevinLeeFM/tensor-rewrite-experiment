import NamedSpec
set_option maxRecDepth 10000
set_option maxHeartbeats 1500000
namespace RevisedBenchmark.NamedMaximum
theorem erf_refuted : ¬ Goal .erf := by
  intro law
  have bad := law 1 0 216 0 14138173 (by decide +kernel) (by decide +kernel) (by decide +kernel)
  exact (by decide +kernel : max (216*2^16) 0 ≠ 14138173) bad
#print axioms erf_refuted
theorem logistic_refuted : ¬ Goal .logistic := by
  intro law
  have bad := law 1 0 187 8388608 12265128 (by decide +kernel) (by decide +kernel) (by decide +kernel)
  exact (by decide +kernel : max (187*2^16) 8388608 ≠ 12265128) bad
#print axioms logistic_refuted
theorem tanh_refuted : ¬ Goal .tanh := by
  intro law
  have bad := law 1 0 195 0 12777430 (by decide +kernel) (by decide +kernel) (by decide +kernel)
  exact (by decide +kernel : max (195*2^16) 0 ≠ 12777430) bad
#print axioms tanh_refuted
end RevisedBenchmark.NamedMaximum
