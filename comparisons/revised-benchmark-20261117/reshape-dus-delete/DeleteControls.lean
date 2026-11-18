import DeleteProof
open RevisedBenchmark.DeleteUpdate
example : original 3 0 2 base noRow = some [4,5,6] := by decide
example : replacement 3 0 2 base noRow = none := by decide
example : replacement 3 1 2 base (fun _ j => 9+j.val) = some [9,10,6] := by decide
example : original 3 1 2 base (fun _ j => 9+j.val) = some [9,10,6] := by decide
example : replacement 3 0 0 base (fun i _ => nomatch i) = some [4,5,6] := by decide
