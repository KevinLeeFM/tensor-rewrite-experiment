module

import SignedPadProof

set_option autoImplicit false

namespace RevisedBenchmark.HandlePad

open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

private def twoAxis (first second : Nat) : Shape 2 :=
  Fin.cases first (fun _ => second)

private theorem axis_cases (axis : Fin 2) : axis = 0 ∨ axis = 1 := by
  have bounded := axis.isLt
  by_cases axisZero : axis.val = 0
  · exact Or.inl (Fin.ext axisZero)
  · exact Or.inr (Fin.ext (by omega))

private def signedParams : Params (twoAxis 1 2) (twoAxis 2 3) where
  low := Fin.cases 1 (fun _ => -1)
  high := Fin.cases 0 (fun _ => 1)
  interior := twoAxis 2 1
  shape axis := by
    rcases axis_cases axis with rfl | rfl <;> decide

private def positiveInput : Tensor (twoAxis 1 2) Nat := fun i => 7 + (i 1).val

private def signedPoint : Index (twoAxis 2 3) :=
  Fin.cases ⟨1, by decide⟩ (fun _ => ⟨1, by change 1 < 3; decide⟩)

private def holePoint : Index (twoAxis 2 3) :=
  Fin.cases ⟨1, by decide⟩ (fun _ => ⟨0, by change 0 < 3; decide⟩)

example : ¬ IsEmptyInput (twoAxis 1 2) := by
  rintro ⟨axis, zero⟩
  rcases axis_cases axis with rfl | rfl <;> contradiction

example : ClearsInterior signedParams 0 := by
  unfold ClearsInterior
  decide

example : ¬ ClearsInterior signedParams 1 := by
  unfold ClearsInterior
  decide

example : tensor signedParams 99 positiveInput =
    tensor (clearUnitInterior signedParams) 99 positiveInput := by
  apply unit_interior signedParams _ _ 99 positiveInput
  · rintro ⟨axis, zero⟩
    rcases axis_cases axis with rfl | rfl <;> contradiction
  · exact ⟨0, by unfold ClearsInterior; decide⟩

-- One changed axis and one retained axis. Both signed edges are preserved.
example :
    (clearUnitInterior signedParams).interior 0 = 0 ∧
    (clearUnitInterior signedParams).interior 1 = 1 ∧
    (clearUnitInterior signedParams).low 1 = -1 ∧
    (clearUnitInterior signedParams).high 1 = 1 := by decide

-- The signed low edge leaves the second original value at coordinate (1,1).
example : tensor signedParams 99 positiveInput signedPoint = 8 := by decide

example : tensor (clearUnitInterior signedParams) 99 positiveInput signedPoint = 8 := by
  decide

-- The other axis retains a padding hole at coordinate (1,0).
example : tensor (clearUnitInterior signedParams) 99 positiveInput holePoint = 99 := by
  decide

-- Clearing all interiors would change both shape and selection on the nonunit axis.
example : extent 2 (-1) 1 0 ≠ extent 2 (-1) 1 1 := by decide

example : sample 2 (-1) 0 0 = some (1 : Fin 2) ∧ sample 2 (-1) 1 0 = none := by decide

private def emptyParams : Params (twoAxis 0 2) (twoAxis 2 2) where
  low := Fin.cases (-1) (fun _ => 0)
  high := Fin.cases 3 (fun _ => 0)
  interior := twoAxis 4 0
  shape axis := by
    rcases axis_cases axis with rfl | rfl <;> decide

private def emptyValues : Tensor (twoAxis 0 2) Nat :=
  fun i => Fin.elim0 (i 0)

private def emptyOutputPoint : Index (twoAxis 2 2) :=
  Fin.cases ⟨1, by decide⟩ (fun _ => ⟨0, by change 0 < 2; decide⟩)

example : IsEmptyInput (twoAxis 0 2) := ⟨0, rfl⟩

example : tensor emptyParams 42 emptyValues emptyOutputPoint = 42 := by decide

example : tensor emptyParams 42 emptyValues = Tensor.constant 42 :=
  empty_input emptyParams ⟨0, rfl⟩ 42 emptyValues

private def croppedAway : Params (fun _ : Fin 1 => 1) (fun _ => 0) where
  low := fun _ => -1
  high := fun _ => 0
  interior := fun _ => 2
  shape _ := by decide

-- Valid unit-interior dispatch with no output coordinates.
example : tensor croppedAway false (fun _ => true) =
    tensor (clearUnitInterior croppedAway) false (fun _ => true) := by
  apply unit_interior croppedAway _ _ false
  · rintro ⟨_, impossible⟩
    contradiction
  · exact ⟨0, by unfold ClearsInterior; decide⟩

example (scalarShape : Shape 0) : ¬ IsEmptyInput scalarShape := by
  rintro ⟨axis, _⟩
  exact Fin.elim0 axis

end RevisedBenchmark.HandlePad
