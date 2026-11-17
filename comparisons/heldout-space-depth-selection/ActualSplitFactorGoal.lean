module
public import RemainingAxisGoals
public import ActualTransportGoal
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualSplitFactorGoal
open TensorRewrite.Pilot TensorRewrite.Pilot.FiniteProduct
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.ChunkIntervals
  Heldout.OriginalSplitConnection Heldout.IndexTransportAttempt
/-- Original split coordinate expressed using the replacement's selected row and local split coordinate. -/
def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    let source := splitFrame shape plan.axes.split
    let axis := concatAxis plan.axes
    let framed := framedInput shape plan.axes.split plan.splitProduct input
    let frame := concatFrame shape plan.axes plan.width
    let position := frame.position (replacementOuterIndex plan input out)
    let q := Fin.cast (chunkBlocks_total source framed axis) position
    (originalIndex plan out plan.axes.split).val =
      (row q).val * plan.width + (replacementOuterIndex plan input out plan.axes.split).val
#print Goal
end Heldout.ActualSplitFactorGoal
