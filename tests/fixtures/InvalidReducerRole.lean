import TensorRewrite

open TensorRewrite.Pilot.ReducerIndex.ScatterRoles

example : before .current .current lhs base 0 5 0 = after .current .current lhs base 0 5 0 := by
  rfl
