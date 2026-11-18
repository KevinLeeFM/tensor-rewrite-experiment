module
import ArgReuseProof

set_option autoImplicit false
open RevisedBenchmark.ArgReuse
open TensorRewrite.Pilot

example : Goal := reuse_arg_extremum
#print axioms RevisedBenchmark.ArgReuse.reuse_arg_extremum

private def oneAxis : Shape 1 := fun _ => 3
private def scalar : Shape 0 := Fin.elim0
private def i (j : Fin 3) : Index oneAxis := fun _ => j
private def sample : Tensor oneAxis (Value 4) := fun j =>
  some (([2, 4, 4] : List (Fin 6))[(j 0).val]?.getD 0)

example := reuse_arg_extremum 4 1 0 oneAxis scalar sample (fun _ => [i 2, i 0, i 1]) 0 .maximum

private def valFold (d : Direction) (js : List (Fin 3)) :=
  js.foldl (fun a j => valueStep d a (sample (i j))) (seed 4 d)
private def pairFold (d : Direction) (js : List (Fin 3)) :=
  js.foldl (fun a j => argStep d a (sample (i j), j.val)) (seed 4 d, 0)

example : pairFold .maximum [2, 0, 1] = (some 4, 1) := by decide
example : valFold .maximum [2, 0, 1] = some 4 := by decide
example : valFold .minimum [2, 0, 1] = some 2 := by decide
example : valFold .minimum [] = some 5 ∧ valFold .maximum [] = some 0 := by decide
example : (argStep (n := 4) .minimum (some 2, 0) (none, 2)).1 = none := by decide
example : (argStep (n := 4) .maximum (none, 2) (some 2, 0)).1 = none := by decide

-- Swapping the sibling reduction's direction produces a different value.
example : valFold .maximum [2, 0, 1] ≠ (pairFold .minimum [2, 0, 1]).1 := by decide
