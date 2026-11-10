module

public import TensorRewrite.Pilot.DependencyOrder

/-! Adding prerequisites restricts the schedules and their event projections.
The node set and labels are fixed; this is not a general node-deletion theorem. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DependencyOrder

/-- A schedule satisfying all added prerequisites also satisfies the original ones. -/
theorem Graph.isSchedule_of_predecessor_inclusion {nodes : Nat} (before after : Graph nodes)
    (included : ∀ node predecessor,
      predecessor ∈ before.predecessors node → predecessor ∈ after.predecessors node)
    (order : List (Fin nodes)) (valid : after.IsSchedule order) : before.IsSchedule order :=
  ⟨valid.1, valid.2.1, valid.2.2.1,
    fun node predecessor member => valid.2.2.2 node predecessor (included node predecessor member)⟩

/-- Adding prerequisites cannot add event traces for the same nodes and labels. -/
theorem Graph.isTrace_of_predecessor_inclusion {nodes : Nat} (before after : Graph nodes)
    (included : ∀ node predecessor,
      predecessor ∈ before.predecessors node → predecessor ∈ after.predecessors node)
    (labels : Fin nodes → Option String) (trace : List String)
    (valid : after.IsTrace labels trace) : before.IsTrace labels trace := by
  obtain ⟨order, schedule, projected⟩ := valid
  exact ⟨order, Graph.isSchedule_of_predecessor_inclusion before after included order schedule,
    projected⟩

end TensorRewrite.Pilot.DependencyOrder
