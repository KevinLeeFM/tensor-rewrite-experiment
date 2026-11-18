import ScatterTransposeProof
open TensorRewrite.Pilot RevisedBenchmark.ScatterT
private def cycle : AxisPermutation 3 := ⟨(·+1), (·+2), by decide, by decide⟩
private def win (a : Fin 3) : Nat := if a = 0 then 2 else 1
private def q : Point 3 := fun a => if a = 2 then 2 else 0
private def e : Entry 3 Int := ([(0,1)], fun k => 5+k 0)
private def step := applyEntry (fun _ => 4) (fun a => win (cycle.outputToInput a)) q
    (fun (a b : Int) => 10*a+b)
example : step 0 (moved cycle e) = 6 := by decide
example : step 0 ([(cycle.outputToInput 0,1)], (moved cycle e).2) = 0 := by decide
example : ([moved cycle e,moved cycle e] : List (Entry 3 Int)).foldl step 0 = 66 := by decide
example : applyEntry (fun _ => 4) win (pull cycle q) (·+·) 7
    ([(0,3)], fun _ => 8) = 7 := by decide
