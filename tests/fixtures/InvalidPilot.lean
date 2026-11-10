import TensorRewrite

open TensorRewrite.Pilot Tensor

private abbrev scalarShape : Shape 0 := fun i => Fin.elim0 i

-- Deliberately invalid mutation: true && true must not become false.
example : map₂ Bool.and (constant true : Tensor scalarShape Bool) (constant true) =
    constant false := by
  rfl
