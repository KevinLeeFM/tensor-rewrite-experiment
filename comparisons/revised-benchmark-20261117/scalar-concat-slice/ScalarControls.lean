module
import ScalarProof
open RevisedBenchmark.ScalarConcatSlice
example : Case := verified

-- The legal original window reaches the third nonempty block, but only start 2 is sampled.
example : extent 2 5 3 = 1 ∧
    slice ([[], [7,8], [], [21,22], [31]] : List (List Nat)).flatten 2 5 3 = [21] ∧
    locate [[], [7,8], [], [21,22], [31]] 2 = some ([21,22], 0) := by decide

-- Nonzero translated start; a wrong reset to zero changes the actual singleton result.
example : slice [7,8,21,22,31] 3 5 9 = slice [21,22] 1 2 9 ∧
    slice [7,8,21,22,31] 3 5 9 ≠ slice [21,22] 0 1 9 := by decide

-- A singleton operand may be returned even when the original interval crossed its end.
example : locate [[5],[17],[31,41]] 1 = some ([17],0) ∧
    slice [5,17,31,41] 1 4 3 = [17] := by decide

-- Counter-controls: empty or multi-sample windows fail the singleton guard.
example : extent 3 3 8 = 0 ∧ extent 1 5 3 = 2 ∧
    locate ([[], []] : List (List Nat)) 0 = none := by decide
