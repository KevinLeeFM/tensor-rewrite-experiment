import LeadingProof
open RevisedBenchmark.LeadingSlice
private def chosen := Box.axis 3 0 3 (.axis 4 2 2 .scalar)
example : build [3,4] 6 6 = some chosen := by decide
example : size chosen = 6 ∧ readPos chosen 5 = 11 := by decide
example : readPos (.axis 3 0 3 (.axis 4 1 2 .scalar)) 5 ≠ 11 := by decide
example : build [3,4] 1 4 = none := by decide
example : build [3,4] 2 2 = none := by decide
example : build [3,4] 6 0 = some (.axis 3 0 0 (.axis 4 2 1 .scalar)) := by decide
