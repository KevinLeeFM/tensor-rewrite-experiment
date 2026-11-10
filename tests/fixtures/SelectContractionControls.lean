import TensorRewrite

open TensorRewrite.Pilot.SelectContraction

example : branchContraction true [] = hoistedContraction true [] := by decide
example : branchContraction false [1, -1] = hoistedContraction false [1, -1] := by decide
example : branchContraction true [2, -1] ≠ hoistedContraction true [2, -1] := by decide
example : branchContraction false [2, -1] ≠ hoistedContraction false [2, -1] := by decide
