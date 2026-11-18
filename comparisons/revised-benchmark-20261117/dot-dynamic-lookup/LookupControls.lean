import LookupProof
open RevisedBenchmark.DotLookup
private def x (i : Fin 3) (k : Fin 2) : Int := 5*(i.val : Int) + k.val
private def y (j : Fin 4) (k : Fin 2) : Int := (j.val : Int) + 2*k.val
example : orig (by decide) false true (-7) 6 x y 0 1 = 43 := by decide
example : repl (by decide) false true (-7) 6 x y 0 1 = 43 := by decide
example : repl (by decide) false false (-7) 6 x y 0 1 ≠ 43 := by decide
example : repl (by decide) true false 2 (-7) x y 0 1 = 43 := by decide
example : orig (m:=1) (k:=0) (n:=1) (by decide) true true 9 0 (fun _ _ => 3)
    (fun _ _ => 5) 0 0 = 0 := by decide
