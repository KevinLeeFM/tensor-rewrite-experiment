import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Dag
open TensorRewrite.Pilot.BooleanDag

def scalarShape : Shape 0 := Fin.elim0
def scalarIndex : Index scalarShape := fun axis => Fin.elim0 axis
def env : Fin 2 → Tensor scalarShape Bool :=
  Fin.cases (Tensor.constant false) (fun _ => Tensor.constant true)

-- Deleting And(true,false) must use the false operand, not the true operand.
example :
    ((Program.bind (.operation .logicalAnd [1, 0]) (.result 0)).eval
      (meaning scalarShape) (fun _ => none) env).map (fun t => t scalarIndex) =
    (((Program.result 0 : Program Opcode 3).mapInputs (dropRef 1)).eval
      (meaning scalarShape) (fun _ => none) env).map (fun t => t scalarIndex) := by
  rfl
