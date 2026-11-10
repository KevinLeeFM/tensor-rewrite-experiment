import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Dag
open TensorRewrite.Pilot.BooleanDag

def scalarShape : Shape 0 := Fin.elim0
def scalarIndex : Index scalarShape := fun axis => Fin.elim0 axis

def inputs : Nat → Option (Tensor scalarShape Bool)
  | 0 => some (Tensor.constant true)
  | 1 => some (Tensor.constant false)
  | _ => none

def prefixEnv : Fin 2 → Tensor scalarShape Bool :=
  Fin.cases (Tensor.constant false) (fun _ => Tensor.constant true)

-- The old node is reference zero. Its new Not result is subsequently shared.
def sharedBody : Program Opcode 3 :=
  .bind (.operation .logicalNot [0])
    (.bind (.operation .logicalAnd [0, 0]) (.result 0))

def original : Program Opcode 2 :=
  .bind (.operation .logicalAnd [1, 0]) sharedBody

def redirected : Program Opcode 2 := sharedBody.mapInputs (dropRef 0)
def wrongTarget : Program Opcode 2 := sharedBody.mapInputs (dropRef 1)

def observe (value : Option (Tensor scalarShape Bool)) : Option Bool :=
  value.map (fun tensor => tensor scalarIndex)

example : observe (original.eval (meaning scalarShape) inputs prefixEnv) = some true := by rfl
example : observe (redirected.eval (meaning scalarShape) inputs prefixEnv) = some true := by rfl
example : observe (wrongTarget.eval (meaning scalarShape) inputs prefixEnv) = some false := by rfl

example : original.eval (meaning scalarShape) inputs prefixEnv =
    redirected.eval (meaning scalarShape) inputs prefixEnv := by
  exact and_rhs_false sharedBody inputs prefixEnv 1 0 rfl

-- A deleted node can itself be the root; an unaffected prefixEnv root also survives.
example : observe ((Program.bind (.operation .logicalAnd [1, 0]) (.result 0)).eval
    (meaning scalarShape) inputs prefixEnv) = some false := by rfl
example : observe (((Program.result 0 : Program Opcode 3).mapInputs (dropRef 0)).eval
    (meaning scalarShape) inputs prefixEnv) = some false := by rfl
example : observe (((Program.result 2 : Program Opcode 3).mapInputs (dropRef 0)).eval
    (meaning scalarShape) inputs prefixEnv) = some true := by rfl

-- Invalid arity and an absent parameter remain failures, not default tensors.
example : (Program.bind (.operation .logicalAnd []) (.result 0) : Program Opcode 0).eval
    (meaning scalarShape) inputs Fin.elim0 = none := by rfl
example : (Program.bind (.parameter 99) (.result 0) : Program Opcode 0).eval
    (meaning scalarShape) inputs Fin.elim0 = none := by rfl

-- Lifting must preserve each newly introduced binding's zero reference.
example : liftRefs (dropRef (0 : Fin 2)) (0 : Fin 4) = 0 := by rfl
example : liftRefs (dropRef (0 : Fin 2)) (1 : Fin 4) = 1 := by rfl

-- Empty tensors have no coordinates; the general graph theorem still applies.
def emptyShape : Shape 1 := fun _ => 0

example (body : Program Opcode 3) (external : Nat → Option (Tensor emptyShape Bool)) :
    (Program.bind (.operation .logicalAnd [1, 0]) body).eval (meaning emptyShape) external
        (fun _ => Tensor.constant false) =
      (body.mapInputs (dropRef 0)).eval (meaning emptyShape) external
        (fun _ => Tensor.constant false) := by
  apply and_lhs_true
  funext index
  exact Fin.elim0 (index 0)
