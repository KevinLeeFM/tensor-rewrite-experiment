import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.LinearIndex
open TensorRewrite.Pilot.DenseLayout

def swap2 : AxisPermutation 2 where
  outputToInput := Fin.rev
  inputToOutput := Fin.rev
  output_input := Fin.rev_rev
  input_output := Fin.rev_rev

def shape23 : Shape 2 := Fin.cases 2 (Fin.cases 3 Fin.elim0)
def shape32 : Shape 2 := Fin.cases 3 (Fin.cases 2 Fin.elim0)
def emptyShape : Shape 2 := Fin.cases 0 (Fin.cases 3 Fin.elim0)
def labels : Tensor shape23 Nat := fun index => (linearize shape23 index).val
def correctCast : Tensor shape32 Nat :=
  bitcastTensor (rowMajor 2) (columnMajor 2) shape32 (by decide) labels
def wrongCast : Tensor shape32 Nat :=
  bitcastTensor (rowMajor 2) (rowMajor 2) shape32 (by decide) labels
def values (tensor : Tensor shape32 Nat) : List Nat :=
  (List.finRange 6).map fun position => tensor (delinearize shape32 position)

theorem compatible2 : MinorOrderMatches swap2 (rowMajor 2) (columnMajor 2) :=
  minorOrderMatches_of_axis _ _ _ (fun _ => rfl)
example : ¬ MinorOrderMatches swap2 (rowMajor 2) (rowMajor 2) := by
  intro compatible
  have axis := minorOrderMatches_axis swap2 (rowMajor 2) (rowMajor 2) compatible 0
  exact (by decide : (1 : Fin 2) ≠ 0) axis
example : values correctCast = [0, 3, 1, 4, 2, 5] := by decide
example : values wrongCast = [0, 1, 2, 3, 4, 5] := by decide
example : values correctCast ≠ values wrongCast := by decide
example : Tensor.transpose swap2 (transpose_extents swap2 (by decide)) labels = correctCast :=
  transpose_eq_bitcast swap2 (rowMajor 2) (columnMajor 2) (by decide) compatible2 labels
example : elementCount ((rowMajor 2).orderedShape emptyShape) = 0 := by rfl

def cycle3 : AxisPermutation 3 where
  outputToInput := fun axis => axis + 1
  inputToOutput := fun axis => axis + 2
  output_input := by decide
  input_output := by decide

def shape234 : Shape 3 := Fin.cases 2 (Fin.cases 3 (Fin.cases 4 Fin.elim0))
def shape342 : Shape 3 := Fin.cases 3 (Fin.cases 4 (Fin.cases 2 Fin.elim0))
def cycleLayout : DenseLayout 3 where
  minorToMajor := {
    outputToInput := fun axis => if axis.val = 0 then 1 else if axis.val = 1 then 0 else 2
    inputToOutput := fun axis => if axis.val = 0 then 1 else if axis.val = 1 then 0 else 2
    output_input := by decide
    input_output := by decide
  }

def rank3Input : Tensor shape234 Nat := fun index =>
  100 * (index ⟨0, by decide⟩).val + 10 * (index ⟨1, by decide⟩).val +
    (index ⟨2, by decide⟩).val
def rank3Output : Tensor shape342 Nat :=
  bitcastTensor (rowMajor 3) cycleLayout shape342 (by decide) rank3Input
def selectedIndex : Index shape342 := delinearize shape342 ⟨1, by decide⟩
def selectedAddress : Nat := (cycleLayout.address selectedIndex).val

example : MinorOrderMatches cycle3 (rowMajor 3) cycleLayout := by
  apply minorOrderMatches_of_axis
  decide
example : rank3Output selectedIndex = 100 ∧ selectedAddress = 12 := by decide
example : (rowMajor 0).read (shape := Fin.elim0) (fun _ => (42 : Nat))
    (fun axis => Fin.elim0 axis) = 42 := by rfl

#eval IO.println ("DENSE_LAYOUT_MODEL correct=" ++
  String.intercalate "," ((values correctCast).map toString))
#eval IO.println ("DENSE_LAYOUT_MODEL wrong=" ++
  String.intercalate "," ((values wrongCast).map toString))
#eval IO.println ("DENSE_LAYOUT_MODEL rank3_selected=" ++ toString (rank3Output selectedIndex) ++
  " address=" ++ toString selectedAddress)
#eval IO.println ("DENSE_LAYOUT_MODEL guards=" ++
  toString (decide (MinorOrderMatches swap2 (rowMajor 2) (columnMajor 2))) ++ "," ++
  toString (decide (MinorOrderMatches swap2 (rowMajor 2) (rowMajor 2))) ++ "," ++
  toString (decide (MinorOrderMatches cycle3 (rowMajor 3) cycleLayout)))
