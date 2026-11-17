module
public import TensorRewrite.Pilot.ReductionRules
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastReduceSingle
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
/-- Single-output logical reduction of an empty input or into an empty output. -/
def Goal : Prop :=
  ∀ {α : Type} (plan : Plan) (operation : α → α → α) (initial : α)
    (input : Tensor plan.inputShape α),
    (elementCount plan.inputShape = 0 ∨ elementCount plan.outputShape = 0) →
    reduceTensor plan operation initial input = Tensor.constant initial
#print Goal
end RevisedBenchmark.BroadcastReduceSingle
