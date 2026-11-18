import MirrorProof
open RevisedBenchmark.DotMirror
private def axes : Axes := [(2,true),(3,false)]
private def x (k : Coord axes) : Int := 1 + 10*(k.1.val : Int) + k.2.1.val
private def y (k : Coord axes) : Int := 3*(k.1.val : Int) - k.2.1.val
example : sumAt axes (fun k => x (mirror axes k) * y k) =
    sumAt axes (fun k => x k * y (mirror axes k)) := by decide
example : sumAt axes (fun k => x (mirror axes k) * y k) ≠
    sumAt axes (fun k => x k * y k) := by decide
example : sumAt [(0,true)] (fun _ => 5) = 0 := by decide
example : sumAt [] (fun _ => -3) = -3 := by decide
example : (TensorRewrite.Pilot.Tensor.reverseIndex (shape := fun _ : Fin 1 => 3)
    (fun _ => true) (fun _ => 0) 0).val = 2 := by decide
