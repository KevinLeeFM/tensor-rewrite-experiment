module
public import ActualMovedExtractionProof
public import ActualAxisGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualMovedExtractionIntegration
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.IndexTransportAttempt
  Heldout.ActualMovedExtractionGoal Heldout.ActualMovedExtractionProof
  Heldout.SourceFrame

/-- The two frozen extraction obligations immediately imply the actual moved-axis case. -/
theorem moved_axis_equality_of_original_extraction
    (originalExtraction : Heldout.ActualMovedExtractionGoal.Goal) :
    ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
      {outer : Shape outerRank} {α : Type}
      (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
      (originalIndex plan out (concatAxis plan.axes)).val =
        (replacementIndex plan input out (concatAxis plan.axes)).val := by
  intro rank outerRank shape inner outer α plan input out
  exact (originalExtraction plan input out).trans
    (ReplacementGoal_proved plan input out).symm

#print axioms moved_axis_equality_of_original_extraction
end Heldout.ActualMovedExtractionIntegration
