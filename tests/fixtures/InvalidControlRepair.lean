import TensorRewrite

open TensorRewrite.Pilot

-- Adding a missing prerequisite cannot be treated as preserving every old schedule.
example : @decide (ControlOrder.repaired.IsSchedule [0, 2, 1, 3])
    (by unfold DependencyOrder.Graph.IsSchedule; infer_instance) = true := by
  rfl
