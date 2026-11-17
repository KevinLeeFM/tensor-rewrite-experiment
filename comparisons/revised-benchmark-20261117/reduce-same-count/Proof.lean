module
public import Goal
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceSameCount
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
/-- The frozen model partition follows directly from the existing reduction rule. -/
theorem goal_proved : Goal := by
  intro α plan operation initial leftIdentity input same
  exact reduceTensor_sameCount plan operation initial leftIdentity input same
#print axioms goal_proved
end RevisedBenchmark.ReduceSameCount
