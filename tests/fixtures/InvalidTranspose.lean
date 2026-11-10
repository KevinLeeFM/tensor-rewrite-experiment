import TensorRewrite

open TensorRewrite.Pilot Tensor

private def swapAxis (axis : Fin 3) : Fin 3 :=
  if axis = 0 then 1 else if axis = 1 then 0 else 2

private def swap01 : AxisPermutation 3 where
  outputToInput := swapAxis
  inputToOutput := swapAxis
  output_input := by decide
  input_output := by decide

private def reverseAxes : AxisPermutation 3 where
  outputToInput := Fin.rev
  inputToOutput := Fin.rev
  output_input := Fin.rev_rev
  input_output := Fin.rev_rev

private abbrev cubeShape : Shape 3 := fun _ => 2

private def coordinateTensor : Tensor cubeShape Nat := fun index => (index 0).val

-- Deliberately invalid: reverse the order of noncommuting permutations.
example : transpose (inputShape := cubeShape) (outputShape := cubeShape) (reverseAxes.comp swap01) (fun _ => rfl) coordinateTensor =
    transpose (inputShape := cubeShape) (outputShape := cubeShape) (swap01.comp reverseAxes) (fun _ => rfl) coordinateTensor := by
  rfl
