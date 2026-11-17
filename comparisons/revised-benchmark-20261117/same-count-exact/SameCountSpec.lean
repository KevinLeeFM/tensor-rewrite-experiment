module
public import TensorRewrite.Pilot.ReductionRules
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SameCountExact
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

/-- A value observation for a fixed input is correct exactly when every observed
    reshaped value is fixed by the reducer with the actual initializer. -/
def PointwiseGoal : Prop :=
  ∀ {α : Type} (plan : Plan) (op : α → α → α) (init : α)
    (same : elementCount plan.inputShape = elementCount plan.outputShape)
    (input : Tensor plan.inputShape α),
    (reduceTensor plan op init input = Reshape.reshapeTensor input plan.outputShape same) ↔
      ∀ j, op init (Reshape.reshapeTensor input plan.outputShape same j) =
        Reshape.reshapeTensor input plan.outputShape same j

/-- For a fixed plan, uniform correctness over all logical inputs has an exact
    exception for empty output. -/
def UniformGoal : Prop :=
  ∀ {α : Type} (plan : Plan) (op : α → α → α) (init : α)
    (same : elementCount plan.inputShape = elementCount plan.outputShape),
    (∀ input, reduceTensor plan op init input =
      Reshape.reshapeTensor input plan.outputShape same) ↔
      elementCount plan.outputShape = 0 ∨ ∀ x, op init x = x
end RevisedBenchmark.SameCountExact
