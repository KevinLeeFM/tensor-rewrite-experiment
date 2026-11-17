module

public import SameCountSpec

public section

set_option autoImplicit false

namespace RevisedBenchmark.SameCountExact

open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

/-- An observed output coordinate forces positive cardinality and a singleton fiber. -/
private theorem reduce_at {α : Type} (plan : Plan) (op : α → α → α) (init : α)
    (same : elementCount plan.inputShape = elementCount plan.outputShape)
    (input : Tensor plan.inputShape α) (j : Index plan.outputShape) :
    reduceTensor plan op init input j =
      op init (Reshape.reshapeTensor input plan.outputShape same j) := by
  have pos := Nat.zero_lt_of_lt (linearize plan.outputShape j).isLt
  have units := unitReducedAxes_of_fiberCount_one plan
    (fiberCount_one_of_sameCount plan same pos)
  unfold reduceTensor
  rw [fiberValues_unit plan units]
  change op init (input (plan.unitIndex units j)) =
    op init (input (Reshape.reshapeIndex plan.inputShape plan.outputShape same j))
  rw [unitIndex_eq_reshapeIndex plan units same j]

/-- Fixed-input correctness requires precisely the initializer law at observed values. -/
theorem pointwise_iff : PointwiseGoal := by
  intro α plan op init same input
  constructor
  · intro eq j
    exact (reduce_at plan op init same input j).symm.trans (congrFun eq j)
  · intro fixes
    funext j
    exact (reduce_at plan op init same input j).trans (fixes j)

/-- A nonempty plan can observe any value by choosing a constant input tensor. -/
theorem uniform_iff : UniformGoal := by
  intro α plan op init same
  constructor
  · intro eq
    by_cases empty : elementCount plan.outputShape = 0
    · exact Or.inl empty
    · refine Or.inr ?_
      intro x
      let j := delinearize plan.outputShape ⟨0, Nat.pos_of_ne_zero empty⟩
      exact (pointwise_iff plan op init same (Tensor.constant x)).mp
        (eq (Tensor.constant x)) j
  · rintro (empty | fixes) input
    · exact Reshape.tensor_eq_of_empty empty _ _
    · exact reduceTensor_sameCount plan op init fixes input same

end RevisedBenchmark.SameCountExact
