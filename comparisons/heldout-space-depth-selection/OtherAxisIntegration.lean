module
public import OtherAxisProof
@[expose] public section
set_option autoImplicit false
namespace Heldout.OtherAxisIntegration
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.IndexTransportAttempt

theorem full_index : Heldout.ActualFullIndexGoal.Goal := by
  intro rank outerRank shape inner outer α plan input out
  funext i
  by_cases hc : i = concatAxis plan.axes
  · subst i
    apply Fin.ext
    exact Heldout.OriginalCoordinateIntegration.moved_axis_equality plan input out
  · by_cases hs : i = plan.axes.split
    · subst i
      exact Heldout.RowMajorSplitIntegration.split plan input out
    · exact Heldout.OtherAxisProof.other plan input out i hc hs

theorem rewrite : Heldout.SpaceDepthCandidate.Goal := by
  intro rank outerRank shape inner outer plan α input
  funext out
  exact read_equal_of_index_equal plan input out (full_index plan input out)

#print Heldout.OtherAxisIntegration.full_index
#print Heldout.OtherAxisIntegration.rewrite
#print axioms full_index
#print axioms rewrite
end Heldout.OtherAxisIntegration
