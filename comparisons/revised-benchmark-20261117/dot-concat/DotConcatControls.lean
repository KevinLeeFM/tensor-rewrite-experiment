import DotConcatProof
open RevisedBenchmark.DotConcat
private def cols : List (Columns 1) := [[fun _ => 1, fun _ => 2], [], [fun _ => -1]]
private def w (t : Nat) : Int := (t+1 : Nat)
example : dotAt false 0 w cols.flatten = 2 := by decide
example : blockSum false 0 w cols 0 0 = 2 := by decide
example : blockSum true 0 w cols 0 0 = 2 := by decide
example : ((cols.map (dotAt false 0 w)).sum) ≠ dotAt false 0 w cols.flatten := by decide
example : blockSum true (0 : Fin 1) w [[],[]] 10 (-7) = -7 := by decide
example : ∀ i : Fin 0, dotAt true i w ([] : Columns 0) = 0 := fun i => nomatch i
