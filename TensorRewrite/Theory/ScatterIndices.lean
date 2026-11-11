module

public import TensorRewrite.Theory.IndexVectorLemmas
public import TensorRewrite.Theory.ScatterLayoutProof

/-! Ordered Scatter from actual raw index and update tensors with independently typed layouts. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterIndices

open Pilot

/-- Read the actual raw index tensor at its vector-axis coordinate and the raw update tensor
at its merged batch/window coordinate. All optional addresses and original event order remain. -/
def entries {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    List (OrderedScatter.Entry plan.operandShape α) :=
  (OrderedCoordinates.enumerate plan.updateAxes.outputShape).flatMap fun batch =>
    (OrderedCoordinates.enumerate (ReductionFiber.shape plan.updateAxes)).map fun window =>
      ⟨OrderedScatter.target? plan.toOrdered
        (fun coordinate component => indices (layout.rawIndex coordinate component))
        batch (plan.windows.expandIndex window),
        updates (ReductionFiber.mergeIndex plan.updateAxes batch window)⟩

/-- Apply the original ordered whole-state reducer to events derived from both raw tensors. -/
def scatter {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    Tensor plan.operandShape α :=
  OrderedScatter.run operation base (entries plan layout indices updates)

end TensorRewrite.Theory.ScatterIndices
