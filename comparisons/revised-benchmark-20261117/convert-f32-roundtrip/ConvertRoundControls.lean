import ConvertRoundProof
open RevisedBenchmark.ConvertRound
example : back true 24 (-16777216) = -16777216 := by decide
example : back true 31 (-16777217) = -16777216 := by decide
example : back false 31 16777217 = 16777216 := by decide
example : fixed false 15 := (verified false 15 (by decide)).2 (by decide)
example : ¬fixed true 31 := fun h => (by decide : ¬ (31 ≤ 24)) ((verified true 31 (by decide)).1 h)
