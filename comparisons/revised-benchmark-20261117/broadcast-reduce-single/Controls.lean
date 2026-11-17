module
public import Proof
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastReduceSingle.Controls
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction
/-- Reducing a zero-length axis leaves a scalar output. -/
def emptyInputPlan : Plan := .reduce 0 .scalar
/-- A scalar output has its unique coordinate. -/
def scalarOutput : Index emptyInputPlan.outputShape := fun axis => Fin.elim0 axis
/-- The input is empty and the output has one element. -/
theorem witnessCounts : elementCount emptyInputPlan.inputShape = 0 ∧
    elementCount emptyInputPlan.outputShape = 1 := by decide
/-- The concrete output has the actual initializer, even for a non-identity operation. -/
theorem witnessValue : reduceTensor emptyInputPlan (fun _ _ : Nat => 99) 7
    (Tensor.constant 42) scalarOutput = 7 := by decide
/-- Replacing that initializer with a different value gives a false equation. -/
theorem wrongInitializer : reduceTensor emptyInputPlan (fun _ _ : Nat => 99) 7
    (Tensor.constant 42) ≠ Tensor.constant 8 := by
  intro h
  have point := congrFun h scalarOutput
  have actual := witnessValue
  change reduceTensor emptyInputPlan (fun _ _ : Nat => 99) 7
    (Tensor.constant 42) scalarOutput = 8 at point
  omega
/-- A kept zero axis produces an empty output domain. -/
def emptyOutputPlan : Plan := .keep 0 .scalar
/-- There is no output coordinate: the empty-output equality is pointwise vacuous. -/
theorem outputVacuous (index : Index emptyOutputPlan.outputShape) : False := by
  have impossible := index ⟨0, by decide⟩
  exact Fin.elim0 impossible
#print axioms witnessCounts
#print axioms witnessValue
#print axioms wrongInitializer
#print axioms outputVacuous
end RevisedBenchmark.BroadcastReduceSingle.Controls
