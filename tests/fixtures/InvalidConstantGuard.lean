import TensorRewrite

open TensorRewrite.Pilot.ConstantGuard

-- Equal first values do not justify ignoring a later nonuniform element.
example : matchesAll true [true, true, false] = true := by
  rfl
