import TensorRewrite

open TensorRewrite.Pilot.SelectContraction

example : branchContraction true [1, 1, 1, 1] = hoistedContraction true [1, 1, 1, 1] := by
  rfl
