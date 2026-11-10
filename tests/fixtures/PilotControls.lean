import TensorRewrite

open TensorRewrite.Pilot Tensor

private abbrev scalarShape : Shape 0 := fun i => Fin.elim0 i

-- Rank zero has an index, so false identities cannot pass vacuously.
example : map₂ Bool.and (constant true : Tensor scalarShape Bool) (constant true) ≠
    constant false := by
  intro h
  have impossible : true = false := congrFun h (fun i => Fin.elim0 i)
  cases impossible

-- An extent of zero creates no legal indices, as required by empty tensors.
example (x y : Tensor (fun (_ : Fin 1) => 0) Bool) : x = y := by
  funext i
  exact Fin.elim0 (i 0)

-- Reversal really changes nontrivial coordinates; it is not defined as identity.
example : reverse (fun _ => true)
    (fun i => (i 0).val : Tensor (fun (_ : Fin 1) => 2) Nat) ≠
    (fun i => (i 0).val) := by
  intro h
  have impossible : 1 = 0 := congrFun h (fun _ => 0)
  cases impossible

-- Modular cancellation remains correct across wraparound boundaries.
example : ((255#8) + (2#8)) - (255#8) = (2#8) := by decide

-- This differs from truncated-natural subtraction when x < y.
example : (3#8) - ((3#8) - (5#8)) = (5#8) := by decide
