module
public import ActualSplitFactorGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.SplitStrategyTarget
open TensorRewrite.Pilot Heldout.SpaceDepthCandidate Heldout.SourceFrame
  Heldout.OriginalSplitConnection Heldout.IndexTransportAttempt
/-- Proposed first gate: extract the source split coordinate from the original inner index. -/
def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank}
    (plan : Conditions shape inner outer) (out : Index outer),
    let q := Tensor.transposeIndex plan.axes.permutation (transpose_extents inner plan.axes.permutation)
      (originalOuterIndex plan out)
    (originalIndex plan out plan.axes.split).val =
      (q plan.axes.split.castSucc).val * plan.width + (q plan.axes.split.succ).val
#print Goal
end Heldout.SplitStrategyTarget
