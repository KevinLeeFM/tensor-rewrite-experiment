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

-- These noncommuting permutations distinguish the order of composition.
example : transpose (inputShape := cubeShape) (outputShape := cubeShape) (reverseAxes.comp swap01) (fun _ => rfl) coordinateTensor ≠
    transpose (inputShape := cubeShape) (outputShape := cubeShape) (swap01.comp reverseAxes) (fun _ => rfl) coordinateTensor := by
  intro h
  have impossible : 1 = 0 := congrFun h (fun axis => if axis = 2 then 1 else 0)
  cases impossible

-- Same indexing convention as XLA's p1[p2[i]] loop.
example : (AxisArray.compose (AxisArray.ofPermutation reverseAxes)
    (AxisArray.ofPermutation swap01))[(0 : Fin 3)] = (1 : Fin 3) := by
  simp only [AxisArray.compose_get, AxisArray.ofPermutation_get]
  decide

example : (AxisArray.compose (AxisArray.ofPermutation reverseAxes)
    (AxisArray.ofPermutation swap01))[(1 : Fin 3)] = (2 : Fin 3) := by
  simp only [AxisArray.compose_get, AxisArray.ofPermutation_get]
  decide

-- Signed negative axes cannot satisfy the decoder's admission predicate.
example : ¬ (∀ i : Fin 1,
    0 ≤ (Vector.ofFn (fun (_ : Fin 1) => (-1 : Int)))[i] ∧
    (Vector.ofFn (fun (_ : Fin 1) => (-1 : Int)))[i] < (1 : Int)) := by
  decide
