import MinMaxProof
open RevisedBenchmark.MinMax
private def rows (r : Fin 3) (i : Fin 6 × Unit) : Int :=
  if r = 0 then 2*(i.1.val : Int) else if r = 1 then 17-(i.1.val : Int) else -4+(i.1.val : Int)
example : reduceScatter (k := 2) .minimum rows 2 (1,()) = 1 := by decide
example : reduceScatter (k := 2) .maximum rows 2 (1,()) = 12 := by decide
example : reduceScatter (k := 2) .maximum rows 0 (1,()) = 16 := by decide
example : allReduce .minimum rows 2 (0,()) = -4 := by decide
example : allReduce .maximum rows 1 (0,()) = 17 := by decide
example : allReduce (g := 0) .maximum (fun _ (_ : Unit) => -9) 0 () = -9 := by decide
example : reduceScatter (g := 1) (k := 0) (C := Empty) .minimum (fun _ _ => -3) = fun _ _ => -3 :=
  ((verified .minimum).2 1 0 Empty (-3))
