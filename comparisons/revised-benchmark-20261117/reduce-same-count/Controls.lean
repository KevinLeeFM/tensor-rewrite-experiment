module
public import Goal
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReduceSameCount.Controls
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

def onePlan : Plan := .reduce 1 .scalar
def oneInput : Tensor onePlan.inputShape Nat := fun _ => 7
def scalarIndex : Index onePlan.outputShape := fun i => Fin.elim0 i
theorem sameOne : elementCount onePlan.inputShape = elementCount onePlan.outputShape := by decide
/-- A nonempty input and output with addition and its actual left identity. -/
example : reduceTensor onePlan Nat.add 0 oneInput scalarIndex = 7 := by decide
example : Reshape.reshapeTensor oneInput onePlan.outputShape sameOne scalarIndex = 7 := by decide
/-- Using 1 as initializer breaks equality even for the same valid input. -/
example : reduceTensor onePlan Nat.add 1 oneInput scalarIndex ≠
    Reshape.reshapeTensor oneInput onePlan.outputShape sameOne scalarIndex := by decide

def emptyPlan : Plan := .keep 0 .scalar
def emptyInput : Tensor emptyPlan.inputShape Nat := fun _ => 7
theorem sameEmpty : elementCount emptyPlan.inputShape = elementCount emptyPlan.outputShape := by decide
/-- A zero extent yields no admitted output indices. -/
example : elementCount emptyPlan.outputShape = 0 := by decide
example : ¬ Nonempty (Index emptyPlan.outputShape) := by
  intro ⟨index⟩
  have zero : elementCount emptyPlan.outputShape = 0 := by decide
  have impossible := linearize emptyPlan.outputShape index
  rw [zero] at impossible
  exact Fin.elim0 impossible
example : reduceTensor emptyPlan Nat.add 0 emptyInput =
    Reshape.reshapeTensor emptyInput emptyPlan.outputShape sameEmpty := by
  exact reduceTensor_sameCount emptyPlan Nat.add 0 (by intro v; exact Nat.zero_add v) emptyInput sameEmpty
end RevisedBenchmark.ReduceSameCount.Controls
