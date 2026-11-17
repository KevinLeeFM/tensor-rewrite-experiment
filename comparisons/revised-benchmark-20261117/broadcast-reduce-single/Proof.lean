module
public import Goal
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastReduceSingle
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
/-- Both empty-domain cases follow from the established reduction rules. -/
theorem proved : Goal := by
  intro α plan operation initial input empty
  rcases empty with inputEmpty | outputEmpty
  · exact reduceTensor_empty_input plan operation initial input inputEmpty
  · exact reduceTensor_empty_output plan operation initial input outputEmpty
#print axioms proved
end RevisedBenchmark.BroadcastReduceSingle
