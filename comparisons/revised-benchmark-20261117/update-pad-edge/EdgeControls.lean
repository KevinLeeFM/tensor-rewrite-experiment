import EdgeProof
open RevisedBenchmark.EdgeUpdate
private def x : Axis Bool Nat := [fun b => if b then 7 else 3, fun _ => 8]
private def y : Axis Bool Nat := [fun _ => 9]
private def view (xs : Axis Bool Nat) := xs.map (fun f => f true)
example : view (update (base true x 1 5) y 10) = [7,8,9] := by decide
example : view (update (base false x 1 5) y (-8)) = [9,7,8] := by decide
example : view (update (base true x 1 5) y 1) ≠ view (x++y) := by decide
example : view (update (base false x 1 5) y 0) ≠ view (x++y) := by decide
