import TraversalProof
open RevisedBenchmark.DotTraversal
example : old false data weights = 16777216 ∧ newDot false data weights = 16777218 := by decide
example : old true data weights = 16777216 ∧ newDot true data weights = 16777218 := by decide
example : old false (fun k => k.val) weights = newDot false (fun k => k.val) weights := by decide
example : List.map flip (List.finRange 4) = [0,2,1,3] := by decide
#check (refuted : ∀ side, ¬ Goal side)
