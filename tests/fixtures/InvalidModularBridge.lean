import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Tensor

-- Legal Broadcast axes still carry essential value information.
def shape : Shape 2 := fun _ => 2
def smallShape : Shape 1 := fun _ => 2
def axes : Bool → IndexMaps.BroadcastAxes 1 2
  | false => {values := #v[0], valid := by decide}
  | true => {values := #v[1], valid := by decide}
theorem extents (axis : Bool) :
    ∀ dimension, smallShape dimension = shape ((axes axis).decode dimension) := fun _ => rfl
def operand : Tensor smallShape (BitVec 8) := fun index => if (index 0).val = 0 then 2 else 3
def moved (axis : Bool) : Tensor shape (BitVec 8) :=
  map₂ (· * ·) (constant 1) (reindex (IndexMaps.broadcastIndex (axes axis) (extents axis))
    (map₂ (· * ·) operand (constant 2)))
def coordinate : Index shape := fun axis =>
  ⟨if axis.val = 0 then 0 else 1, by dsimp [shape]; split <;> decide⟩

example : (moved false coordinate).toNat = (moved true coordinate).toNat := by
  rfl
