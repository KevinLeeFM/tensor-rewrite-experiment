module
public import GoalCandidate
public import RecursiveShapeSplit
/-! Instantiate the generic split at the plan's checked moved axis. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.PlanShapeSplit
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.FiniteProduct
  Heldout.SourceFrame Heldout.SpaceDepthCandidate Heldout.RecursiveShapeSplit

/-- The moved axis determines a legal prefix cut in the transposed rank. -/
theorem cut_rank {rank : Nat} (axes : AxisConditions rank) :
    (rank + 1 - axes.moved.val) + axes.moved.val = rank + 1 :=
  Nat.sub_add_cancel (Nat.le_of_lt axes.moved.isLt)

/-- The transposed inner shape indexed at the rank required by the generic cut. -/
def cutShape {rank : Nat} (axes : AxisConditions rank) (inner : Shape (rank + 1)) :
    Shape ((rank + 1 - axes.moved.val) + axes.moved.val) :=
  fun i => transposedShape inner axes.permutation (Fin.cast (cut_rank axes) i)

/-- The original transposed index viewed through that same rank cast. -/
def cutIndex {rank : Nat} (axes : AxisConditions rank) (inner : Shape (rank + 1))
    (index : Index (transposedShape inner axes.permutation)) : Index (cutShape axes inner) :=
  fun i => index (Fin.cast (cut_rank axes) i)

/-- The actual plan's cast transposed shape has the generic prefix/tail count. -/
theorem plan_count_split {rank : Nat} (axes : AxisConditions rank) (inner : Shape (rank + 1)) :
    elementCount (cutShape axes inner) =
      elementCount (preShape (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutShape axes inner)) *
      elementCount (tailShape (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutShape axes inner)) :=
  full_count_split (cutShape axes inner)

/-- The actual plan's cast transposed coordinate splits at its moved axis. -/
theorem plan_index_split {rank : Nat} (axes : AxisConditions rank) (inner : Shape (rank + 1))
    (index : Index (transposedShape inner axes.permutation)) :
    (linearize (cutShape axes inner) (cutIndex axes inner index)).val =
      (join (linearize (preShape (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutShape axes inner))
        (preIndex (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutIndex axes inner index)))
        (linearize (tailShape (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutShape axes inner))
        (tailIndex (m := axes.moved.val) (n := rank + 1 - axes.moved.val) (cutIndex axes inner index)))).val :=
  full_linearize_split (cutIndex axes inner index)

#print axioms cut_rank
#print axioms plan_count_split
#print axioms plan_index_split
end Heldout.PlanShapeSplit
