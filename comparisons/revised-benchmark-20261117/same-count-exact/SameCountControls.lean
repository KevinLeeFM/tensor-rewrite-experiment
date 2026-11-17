module

import SameCountProof

set_option autoImplicit false

namespace RevisedBenchmark.SameCountExact

open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

private abbrev nonemptyPlan : Plan := .reduce 1 (.keep 2 .scalar)

private abbrev emptyPlan : Plan := .reduce 2 (.keep 0 .scalar)

/-- A positive-size output with the actual additive identity admits all inputs. -/
example : ∀ input : Tensor nonemptyPlan.inputShape Nat,
    reduceTensor nonemptyPlan Nat.add 0 input =
      Reshape.reshapeTensor input nonemptyPlan.outputShape rfl :=
  (uniform_iff nonemptyPlan Nat.add 0 rfl).mpr (Or.inr Nat.zero_add)

/-- Changing just the initializer produces unequal observations on the same input. -/
example :
    reduceTensor nonemptyPlan Nat.add 1 (Tensor.constant 7) ≠
      Reshape.reshapeTensor (Tensor.constant (α := Nat) 7) nonemptyPlan.outputShape
        (inputShape := nonemptyPlan.inputShape) rfl := by
  intro eq
  let j := delinearize nonemptyPlan.outputShape ⟨0, by decide⟩
  have bad := (pointwise_iff nonemptyPlan Nat.add 1 rfl (Tensor.constant 7)).mp eq j
  exact (by decide : ¬(1 + 7 = (7 : Nat))) bad

/-- A zero kept extent permits a nonunit reduced extent and a nonidentity initializer. -/
example : ∀ input : Tensor emptyPlan.inputShape Nat,
    reduceTensor emptyPlan Nat.add 1 input =
      Reshape.reshapeTensor input emptyPlan.outputShape rfl :=
  (uniform_iff emptyPlan Nat.add 1 rfl).mpr (Or.inl rfl)

/-- A reducer can fix the entire observed input without a uniform identity law. -/
example :
    (reduceTensor nonemptyPlan (fun init _ => init) 7 (Tensor.constant 7) =
      Reshape.reshapeTensor (Tensor.constant (α := Nat) 7) nonemptyPlan.outputShape
        (inputShape := nonemptyPlan.inputShape) rfl) ∧
      ¬(∀ x : Nat, (fun (init _ : Nat) => init) 7 x = x) := by
  constructor
  · exact (pointwise_iff nonemptyPlan (fun init _ => init) 7 rfl (Tensor.constant 7)).mpr
      (fun _ => rfl)
  · intro fixes
    exact (by decide : ¬(7 = (0 : Nat))) (fixes 0)

#print axioms pointwise_iff
#print axioms uniform_iff

end RevisedBenchmark.SameCountExact
