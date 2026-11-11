module

public import TensorRewrite.Theory.ScatterBatchingProof

/-! Forgetting actual operand/index batching changes which operand slice receives an update. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterBatching

open Pilot

/-- Two singleton windows, one in each operand batch slice, with an empty index vector. -/
def exampleScatter : ScatterLayout.Plan 0 where
  updateAxes := .keep 2 (.reduce 1 .scalar)
  windows := .insert (.keep 1 .scalar)
  operandShape := Fin.cases 2 (fun _ => 1)
  indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  injective := fun axis => Fin.elim0 axis

/-- Actual operand axis zero is paired with the original index-batch axis zero. -/
def examplePairing : Plan exampleScatter 1 where
  operandAxes := ⟨#v[0], by decide⟩
  indexBatchAxes := ⟨#v[0], by decide⟩
  operand_injective := fun a b _ => Subsingleton.elim a b
  index_injective := fun a b _ => Subsingleton.elim a b
  extents := by decide
  inserted := by decide
  disjoint := fun component => Fin.elim0 component

/-- Actual raw shape[0,2] has no index value, but its batch coordinates still select slices. -/
def exampleLayout : IndexVector.Layout 0 exampleScatter.updateAxes.outputShape :=
  .here 0 exampleScatter.updateAxes.outputShape

/-- The zero-component raw index tensor cannot be queried at any actual bounded coordinate. -/
def exampleIndices : Tensor exampleLayout.rawShape Int := by
  change Tensor (Fin.cases 0 exampleScatter.updateAxes.outputShape) Int
  exact fun raw => Fin.elim0 (raw 0)

/-- Actual paired batching gives1 and2 in separate slices; forgetting batching produces12 and0.
The same raw values, decimal reducer and declared event order are used on both sides. -/
theorem forgetting_batching_refuted :
    let updates : Tensor exampleScatter.updateAxes.inputShape Nat :=
      fun raw => (raw ⟨0, by decide⟩).val + 1
    let first : Index exampleScatter.operandShape :=
      fun axis => ⟨0, by decide +revert⟩
    let second : Index exampleScatter.operandShape := fun axis =>
      ⟨if axis.val = 0 then 1 else 0, by decide +revert⟩
    run exampleScatter examplePairing exampleLayout (fun a b => 10 * a + b)
        (Tensor.constant 0) exampleIndices updates first = 1 ∧
      run exampleScatter examplePairing exampleLayout (fun a b => 10 * a + b)
        (Tensor.constant 0) exampleIndices updates second = 2 ∧
      ScatterIndices.scatter exampleScatter exampleLayout (fun a b => 10 * a + b)
        (Tensor.constant 0) exampleIndices updates first = 12 ∧
      ScatterIndices.scatter exampleScatter exampleLayout (fun a b => 10 * a + b)
        (Tensor.constant 0) exampleIndices updates second = 0 := by
  decide

end TensorRewrite.Theory.ScatterBatching
