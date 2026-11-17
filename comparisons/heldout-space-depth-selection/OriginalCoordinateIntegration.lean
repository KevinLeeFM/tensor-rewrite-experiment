module
public import ActualMovedExtractionIntegration
public import OriginalCoordinateProof
@[expose] public section
set_option autoImplicit false
namespace Heldout.OriginalCoordinateIntegration

theorem moved_axis_equality
    {rank outerRank : Nat} {shape : TensorRewrite.Pilot.Shape rank}
    {inner : TensorRewrite.Pilot.Shape (rank + 1)} {outer : TensorRewrite.Pilot.Shape outerRank}
    {α : Type} (plan : Heldout.SpaceDepthCandidate.Conditions shape inner outer)
    (input : TensorRewrite.Pilot.Tensor shape α)
    (out : TensorRewrite.Pilot.Index outer) :
    (Heldout.IndexTransportAttempt.originalIndex plan out (Heldout.SourceFrame.concatAxis plan.axes)).val =
      (Heldout.IndexTransportAttempt.replacementIndex plan input out
        (Heldout.SourceFrame.concatAxis plan.axes)).val :=
  Heldout.ActualMovedExtractionIntegration.moved_axis_equality_of_original_extraction
    Heldout.OriginalCoordinateProof.Goal_proved plan input out

#print axioms moved_axis_equality
end Heldout.OriginalCoordinateIntegration
