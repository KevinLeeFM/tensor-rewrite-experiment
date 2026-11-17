module
public import IndexTransportAttempt
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualFullIndexGoal
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.IndexTransportAttempt
/-- Equality of actual original and replacement source indices for every admitted output. -/
def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    originalIndex plan out = replacementIndex plan input out
#print Goal
end Heldout.ActualFullIndexGoal
