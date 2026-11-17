module
public import ActualFullIndexGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.RemainingAxisGoals
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.IndexTransportAttempt
/-- The original and replacement coordinates agree at the split axis. -/
def Split : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    originalIndex plan out plan.axes.split = replacementIndex plan input out plan.axes.split
/-- The original and replacement coordinates agree at every other axis. -/
def Other : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer)
    (i : Fin rank), i ≠ concatAxis plan.axes → i ≠ plan.axes.split →
      originalIndex plan out i = replacementIndex plan input out i
#print Split
#print Other
end Heldout.RemainingAxisGoals
