module
public import TensorGoal
public import Proof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeRank
open TensorRewrite.Pilot TensorRewrite.Pilot.SliceShape TensorRewrite.Pilot.IndexMaps
/-- The frozen logical tensor-value goal follows pointwise from index composition. -/
theorem tensorCorrectness : TensorGoal := by
  intro rank inputShape middleShape outputShape α input inner outer hi ho his hos
  obtain ⟨valid, hindex⟩ := correctness inner outer hi ho his hos
  refine ⟨valid, ?_⟩
  intro innerValid outerValid
  funext index
  exact congrArg input (hindex innerValid outerValid index)
#print axioms tensorCorrectness
end RevisedBenchmark.SliceComposeRank
