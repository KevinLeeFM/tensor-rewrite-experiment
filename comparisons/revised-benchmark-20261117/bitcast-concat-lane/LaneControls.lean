import LaneProof
open RevisedBenchmark.LaneConcat
example : before 2 1 [3] = some [3] ∧ after 1 [3] = none := by decide
example : before 2 2 [3] = none ∧ before 2 0 [3] = none := by decide
example : before 2 1 [] = some [] ∧ after 1 [] = none := by decide
example : concat 2 0 [3,2] = some [6,2] ∧ concat 2 0 [3] = some [6] := by decide
