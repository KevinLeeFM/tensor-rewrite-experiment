import TensorRewrite

open TensorRewrite.Pilot
open TensorRewrite.Pilot.ConstantGuard

def scalarShape : Shape 0 := Fin.elim0
def scalarIndex : Index scalarShape := fun axis => Fin.elim0 axis
def scalarTrue : DenseLiteral scalarShape :=
  { storage := [true], address := fun _ => 0 }
def scalarView : View 0 scalarShape := .literal scalarTrue
def vectorShape : Shape 1 := fun _ => 2

-- Rank-changing broadcast followed by another recognized wrapper.
def chain : View 1 vectorShape :=
  .reindex .reverse (.reindex .broadcast scalarView (fun _ => scalarIndex)) id

example : chain.isAll true = true := by rfl
example : chain.isAll false = false := by rfl
example : chain.eval = Tensor.constant true := chain.isAll_sound true rfl

example : matchesAll true [true, false] = false := by rfl
example : matchesAll false [true, false] = false := by rfl
example : matchesAll true [] = true := by rfl
example : matchesAll false [] = true := by rfl
example : matchesAll true [true, true, true] = true := by rfl
example : matchesAll false [false, false, false] = true := by rfl

-- An unsupported operation can be uniform without being recognized.
example : (View.unrecognized (Tensor.constant true) : View 0 scalarShape).isAll true = false := by
  rfl

-- Empty storage is legal only when there is no coordinate needing an address.
def emptyShape : Shape 1 := fun _ => 0
def emptyLiteral : DenseLiteral emptyShape :=
  { storage := [], address := fun index => Fin.elim0 (index 0) }

example : (View.literal emptyLiteral).isAll true = true := by rfl
example : (View.literal emptyLiteral).isAll false = true := by rfl
example : emptyLiteral.eval = Tensor.constant true := emptyLiteral.matchesAll_sound true rfl
