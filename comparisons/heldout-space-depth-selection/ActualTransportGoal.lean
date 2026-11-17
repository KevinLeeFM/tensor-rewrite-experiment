module
public import ActualMergedProof
public import ActualSuffixProof
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualTransportGoal
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex
  TensorRewrite.Theory.Concatenation Heldout.SliceTransport
  Heldout.RecursiveShapeSplit
  Heldout.SpaceDepthCandidate Heldout.SourceFrame Heldout.ChunkIntervals
  Heldout.OriginalSplitConnection Heldout.TailHeadConnection
  Heldout.ActualMergedProof

def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    ((concatFrame shape plan.axes plan.width).position (replacementOuterIndex plan input out)).val =
      (originalOuterIndex plan out plan.axes.moved).val * shape (concatAxis plan.axes) +
        (originalOuterIndex plan out ⟨plan.axes.moved.val + 1, by
          have hm := Heldout.SourceFrame.moved_before_split plan.axes
          have hs := plan.axes.split.isLt
          omega⟩).val
#print Goal
end Heldout.ActualTransportGoal
