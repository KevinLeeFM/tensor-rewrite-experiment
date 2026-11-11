module

public import TensorRewrite.Theory.ScatterIndicesProof

/-! An empty raw index tensor can contain an explicit zero-length vector for a nonempty batch. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterIndices

open Pilot

/-- Two actual updates with no index-vector components and one full operand-window element. -/
def emptyVectorPlan : ScatterLayout.Plan 0 where
  updateAxes := .keep 2 (.reduce 1 .scalar)
  windows := .keep 1 .scalar
  operandShape := fun _ => 1
  indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  injective := fun axis => Fin.elim0 axis

/-- The raw index tensor has shape[0,2]: its vector axis is empty, its batch axis is not. -/
def emptyVectorLayout : IndexVector.Layout 0 emptyVectorPlan.updateAxes.outputShape :=
  .here 0 emptyVectorPlan.updateAxes.outputShape

/-- No raw value exists at a coordinate of the zero-length vector dimension. -/
def emptyRawIndices : Tensor emptyVectorLayout.rawShape Int := by
  change Tensor (Fin.cases 0 emptyVectorPlan.updateAxes.outputShape) Int
  exact fun raw => Fin.elim0 (raw 0)

/-- Actual raw index emptiness does not remove the two ordered updates or reduce them to one
pointwise Map: the original decimal result is12, while the first-update Map gives1. -/
theorem empty_index_tensor_not_single_map :
    let updates : Tensor emptyVectorPlan.updateAxes.inputShape Nat :=
      fun raw => (raw ⟨0, by decide⟩).val + 1
    LinearIndex.elementCount emptyVectorLayout.rawShape = 0 ∧
      (entries emptyVectorPlan emptyVectorLayout emptyRawIndices updates).length = 2 ∧
      scatter emptyVectorPlan emptyVectorLayout (fun a b => 10 * a + b) (Tensor.constant 0)
        emptyRawIndices updates (fun _ => ⟨0, by decide +revert⟩) = 12 ∧
      Tensor.map₂ (fun a b => 10 * a + b) (Tensor.constant 0) (Tensor.constant 1)
        (fun _ : Fin 1 => (0 : Fin 1)) = 1 := by
  decide

end TensorRewrite.Theory.ScatterIndices
