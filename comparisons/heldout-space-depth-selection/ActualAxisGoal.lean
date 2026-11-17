module
public import ActualFullIndexGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualAxisGoal
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.IndexTransportAttempt
/-- The actual original and replacement input coordinates agree at each axis. -/
def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer)
    (i : Fin rank), (originalIndex plan out i).val = (replacementIndex plan input out i).val
#print Goal
end Heldout.ActualAxisGoal
