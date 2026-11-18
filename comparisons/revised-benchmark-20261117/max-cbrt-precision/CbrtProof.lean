import CbrtSpec
set_option autoImplicit false
namespace RevisedBenchmark.MaxCbrt
theorem refuted : ¬ Case := by
  intro h
  have impossible := h 2 1 161 8388608 10568984 (by decide) (by decide) (by decide)
  exact (by decide : max (161*2^16) 8388608 ≠ 10568984) impossible
#print axioms refuted
end RevisedBenchmark.MaxCbrt
