module

public import TensorRewrite.Theory.ScatterLayoutProof

/-! Raw update storage order is a distinct observation from declared batch/window event order. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterLayout

open Pilot

/-- Diagnostic alternate trace: enumerate the raw tensor in storage order, then project its
batch/window axes. This is deliberately distinct from the model's declared event order. -/
def storageEntries {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    List (OrderedScatter.Entry plan.operandShape α) :=
  (OrderedCoordinates.enumerate plan.updateAxes.inputShape).map fun raw =>
    ⟨OrderedScatter.target? plan.toOrdered indices
      (ReductionFiber.outputIndex plan.updateAxes raw)
      (plan.windows.expandIndex (ReductionFiber.reducedIndex plan.updateAxes raw)), updates raw⟩

/-- A window/batch raw tensor whose overlapping windows expose an order change. -/
def interleavedExample : Plan 1 where
  updateAxes := .reduce 2 (.keep 2 .scalar)
  windows := .keep 2 .scalar
  operandShape := fun _ => 1
  indexAxes := ⟨#v[0], by decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- Actual interleaved tensor values give112 in declared batch/window order and31 in raw
storage order under the same nonassociative reducer. No external scheduler claim is made. -/
theorem raw_storage_order_refuted :
    let indices : Tensor interleavedExample.updateAxes.outputShape (Fin 1 → Int) :=
      fun batch _ => Int.ofNat (batch ⟨0, by decide⟩).val - 1
    let updates : Tensor interleavedExample.updateAxes.inputShape Nat :=
      fun raw => 10 * (raw ⟨0, by decide⟩).val + (raw ⟨1, by decide⟩).val + 1
    scatter interleavedExample (fun a b => 10 * a + b) (Tensor.constant 0) indices updates
        (fun _ => ⟨0, by decide +revert⟩) = 112 ∧
      OrderedScatter.run (fun a b => 10 * a + b) (Tensor.constant 0)
        (storageEntries interleavedExample indices updates)
        (fun _ => ⟨0, by decide +revert⟩) = 31 := by
  decide

end TensorRewrite.Theory.ScatterLayout
