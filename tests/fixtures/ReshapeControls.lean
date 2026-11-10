import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.LinearIndex
open TensorRewrite.Pilot.Reshape

def shape23 : Shape 2 := Fin.cases 2 (Fin.cases 3 Fin.elim0)
def shape32 : Shape 2 := Fin.cases 3 (Fin.cases 2 Fin.elim0)
def shape6 : Shape 1 := Fin.cases 6 Fin.elim0
def shape11 : Shape 2 := Fin.cases 1 (Fin.cases 1 Fin.elim0)
def scalarShape : Shape 0 := Fin.elim0
def emptyShape : Shape 3 := Fin.cases 2 (Fin.cases 0 (Fin.cases 3 Fin.elim0))

def labels : Tensor shape23 Nat := fun index => (linearize shape23 index).val
def outputValues : List Nat := (List.finRange 6).map fun position =>
  reshapeTensor labels shape32 (by decide) (delinearize shape32 position)
def composedValues : List Nat := (List.finRange 6).map fun position =>
  reshapeTensor (reshapeTensor labels shape32 (by decide)) shape6 (by decide)
    (delinearize shape6 position)

example : outputValues = [0, 1, 2, 3, 4, 5] := by decide
example : composedValues = [0, 1, 2, 3, 4, 5] := by decide
example : elementCount scalarShape = 1 := by rfl
example : elementCount emptyShape = 0 := by rfl
example : reshapeTensor (inputShape := shape11) (Tensor.constant (42 : Nat)) scalarShape
    (by decide) (fun axis => Fin.elim0 axis) = 42 := by rfl

#eval IO.println ("RESHAPE_MODEL values=" ++ String.intercalate "," (outputValues.map toString))
#eval IO.println ("RESHAPE_MODEL composed=" ++ String.intercalate "," (composedValues.map toString))
#eval IO.println ("RESHAPE_MODEL empty=" ++ toString (elementCount emptyShape))
