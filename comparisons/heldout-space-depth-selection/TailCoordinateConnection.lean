module
public import TailCountIntegration
/-! Connect the actual packed tails of the frozen original and replacement reshapes. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.TailCoordinateConnection
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex
  Heldout.SpaceDepthCandidate Heldout.RecursiveShapeSplit
  Heldout.PlanShapeSplit
  Heldout.OriginalSplitConnection Heldout.TailHeadConnection
  Heldout.WorkerIndexJoin Heldout.WorkerIndexPrefix
  Heldout.TailCountIntegration

/-- The actual tail coordinates in the two outer reshape frames have equal packed values.
This uses only the equal full packed position, equal prefix shape/count, and derived tail count. -/
theorem actual_tail_packed_values_equal {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer) :
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (tailIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out)))).val =
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (tailIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out))).val := by
  have samePreCount := congrArg elementCount (prefix_shapes_equal plan input)
  have sameTailCount := plan_tail_count plan input
  have packed := outer_packed_parts_equal plan input out
  unfold packedParts at packed
  have components := packed_component_values samePreCount sameTailCount
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (preIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out))))
    (linearize (preShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (preIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out)))
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank + 1 - plan.axes.moved.val) (cutShape plan.axes inner))
      (tailIndex (m := plan.axes.moved.val) (n := rank + 1 - plan.axes.moved.val)
        (cutIndex plan.axes inner (originalOuterIndex plan out))))
    (linearize (tailShape (m := plan.axes.moved.val)
      (n := rank - plan.axes.moved.val) (replacementCutShape plan input))
      (tailIndex (m := plan.axes.moved.val) (n := rank - plan.axes.moved.val)
        (replacementCutIndex plan input out))) packed
  exact components.2

#print axioms actual_tail_packed_values_equal
end Heldout.TailCoordinateConnection
