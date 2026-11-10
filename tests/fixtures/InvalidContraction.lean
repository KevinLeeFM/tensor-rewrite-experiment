import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Contraction

/-- Dropping the second contracted term changes the actual two-term Dot. -/
def twoTerms : Plan 0 0 0 1 where
  batchShape := Fin.elim0
  leftShape := Fin.elim0
  rightShape := Fin.elim0
  contractShape := fun _ => 2
  leftOrder := AxisPermutation.identity 1
  rightOrder := AxisPermutation.identity 1

example : dotTensor twoTerms (· + ·) (0 : Int) (· * ·) id
    (fun index => if (index 0).val = 0 then 1 else 2)
    (fun index => if (index 0).val = 0 then 3 else 4) (fun axis => Fin.elim0 axis) = 3 := by
  rfl
