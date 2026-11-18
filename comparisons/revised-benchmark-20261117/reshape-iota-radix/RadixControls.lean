import RadixProof
open RevisedBenchmark.RadixIota
example : floating 2 16777217 1 1 = (16777218,16777216) := by decide
example : floating 2 8 1 1 = (9,9) := by decide
example : r32 16777219 = 16777220 := by decide
example : r32 16777217 = 16777216 := by decide
private def ds : List Digit := [⟨4,3⟩,⟨3,1⟩,⟨2,1⟩]
example : linear ds = 19 := by decide
example : loop 4 [⟨3,1⟩,⟨2,1⟩] 4 3 = 3 := by decide
example : loop 8 [⟨3,1⟩,⟨2,1⟩] 1 3 ≠ BitVec.ofNat 8 (linear ds) := by decide
