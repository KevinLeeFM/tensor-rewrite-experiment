module
public import TensorRewrite.Pilot.ReductionRules
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceSameCount
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
/-- Single-output same-count reduction with the actual initial value as left identity. -/
def Goal : Prop :=
  ∀ {α : Type} (plan : Plan) (operation : α → α → α) (initial : α),
    (∀ value, operation initial value = value) →
    ∀ (input : Tensor plan.inputShape α)
      (same : elementCount plan.inputShape = elementCount plan.outputShape),
      reduceTensor plan operation initial input = Reshape.reshapeTensor input plan.outputShape same
#print Goal
end RevisedBenchmark.ReduceSameCount
