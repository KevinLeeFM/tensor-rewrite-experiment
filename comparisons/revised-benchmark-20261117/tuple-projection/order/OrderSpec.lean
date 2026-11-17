module
public import TensorRewrite.Pilot.DependencyOrder
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleProjection.Order
open TensorRewrite.Pilot.DependencyOrder

/-- 0 is x, 1 is effect A, 2 builds (x,A), 3 projects component 0, 4 is
    effect B using the projection, 5 roots both A and B. All edges are data. -/
def before : Graph 6 where
  predecessors n := match n.val with
    | 2 => [0, 1]
    | 3 => [2]
    | 4 => [3]
    | 5 => [1, 4]
    | _ => []

/-- B now reads x directly; A and B are both still required by the root. -/
def after : Graph 4 where
  predecessors n := match n.val with
    | 2 => [0]
    | 3 => [1, 2]
    | _ => []

/-- Every post-rewrite schedule can be matched by an original schedule with
    the same relative order of A and B, in this data-prerequisite model. -/
def Refines : Prop :=
  ∀ post, after.IsSchedule post → ∃ pre, before.IsSchedule pre ∧
    (post.idxOf 1 < post.idxOf 2 ↔ pre.idxOf 1 < pre.idxOf 4)
end RevisedBenchmark.TupleProjection.Order
