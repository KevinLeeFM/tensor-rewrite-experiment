module
public import ActualTransportGoal
public import ActualFullIndexGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualMovedExtractionGoal
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.IndexTransportAttempt Heldout.OriginalSplitConnection
/-- The original input's moved-axis coordinate is the successor coordinate
in the outer transpose frame. This is one side of the moved-axis equality. -/
def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    (originalIndex plan out (concatAxis plan.axes)).val =
      (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
        have before := moved_before_split plan.axes
        have bound := plan.axes.split.isLt
        omega⟩).val
def ReplacementGoal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    (replacementIndex plan input out (concatAxis plan.axes)).val =
      (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
        have before := moved_before_split plan.axes
        have bound := plan.axes.split.isLt
        omega⟩).val
#print Goal
#print ReplacementGoal
end Heldout.ActualMovedExtractionGoal
