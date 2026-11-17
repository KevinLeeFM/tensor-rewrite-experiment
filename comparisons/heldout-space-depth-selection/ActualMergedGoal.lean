module
public import TailCoordinateConnection
public import MergedHeadConnection
public import WorkerSuffix
@[expose] public section
set_option autoImplicit false
namespace Heldout.ActualMergedGoal
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex
  Heldout.SpaceDepthCandidate Heldout.RecursiveShapeSplit
  Heldout.SourceFrame Heldout.ChunkIntervals Heldout.TailCoordinateConnection Heldout.TailHeadConnection
  Heldout.TailCountIntegration Heldout.PlanShapeSplit Heldout.OriginalSplitConnection

def Goal : Prop :=
  ∀ {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer),
    let m := plan.axes.moved.val
    let k := rank - m - 1
    let leftRank : k + 2 = rank + 1 - m := by
      have before := moved_before_split plan.axes
      have bound := plan.axes.split.isLt
      dsimp [k, m]; omega
    let rightRank : k + 1 = rank - m := by
      have before := moved_before_split plan.axes
      have bound := plan.axes.split.isLt
      dsimp [k, m]; omega
    let leftShape : Shape (k + 2) := fun i =>
      tailShape (m := m) (n := rank + 1 - m) (cutShape plan.axes inner) (Fin.cast leftRank i)
    let rightShape : Shape (k + 1) := fun i =>
      tailShape (m := m) (n := rank - m) (replacementCutShape plan input) (Fin.cast rightRank i)
    let leftIndex : Index leftShape := fun i =>
      tailIndex (m := m) (n := rank + 1 - m)
        (cutIndex plan.axes inner (originalOuterIndex plan out)) (Fin.cast leftRank i)
    let rightIndex : Index rightShape := fun i =>
      tailIndex (m := m) (n := rank - m) (replacementCutIndex plan input out) (Fin.cast rightRank i)
    (preIndex (m := 1) (n := k) rightIndex 0).val =
      (preIndex (m := 2) (n := k) leftIndex 0).val *
        (preShape (m := 2) (n := k) leftShape 1) +
      (preIndex (m := 2) (n := k) leftIndex 1).val
#print Goal
end Heldout.ActualMergedGoal
