import BaseProof
namespace RevisedBenchmark.ReduceBase
example : (original examplePlan values 0, original examplePlan values 1) = (12,-9) := by decide
example : (replacement examplePlan values 0, replacement examplePlan values 1) = (4,-3) := by decide
example : examplePlan.inputRows ≠ examplePlan.outputRows := by decide
#check (refuted : ¬ Goal)
end RevisedBenchmark.ReduceBase
