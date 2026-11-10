import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Tensor

namespace ModularBridgeControls

/-- Shapes whose two legal broadcast-axis choices have different values. -/
def shape : Shape 2 := fun _ => 2

def smallShape : Shape 1 := fun _ => 2

def scalarShape : Shape 0 := Fin.elim0

/-- A captured operand-order/axis test recipe. -/
structure Recipe where
  name : String
  family : String
  left : Bool := false
  right : Bool := false
  outer : Bool := false
  axis : Bool := false
  deriving Repr

def bit (value : Bool) : String := if value then "1" else "0"

/-- Generate all native orientation alternatives, followed by guard controls. -/
def recipes : Array Recipe := Id.run do
  let mut rows := #[]
  for left in [false, true] do
    for right in [false, true] do
      rows := rows.push {
        name := "factor_" ++ bit left ++ bit right
        family := "factor"
        left := left
        right := right
      }
  for left in [false, true] do
    for outer in [false, true] do
      rows := rows.push {
        name := "product_" ++ bit left ++ bit outer
        family := "product"
        left := left
        outer := outer
      }
  for left in [false, true] do
    for right in [false, true] do
      for outer in [false, true] do
        rows := rows.push {
          name := "four_" ++ bit left ++ bit right ++ bit outer
          family := "four"
          left := left
          right := right
          outer := outer
        }
  for axis in [false, true] do
    for left in [false, true] do
      for outer in [false, true] do
        rows := rows.push {
          name := "move_" ++ bit axis ++ "_" ++ bit left ++ bit outer
          family := "move"
          left := left
          outer := outer
          axis := axis
        }
  for name in ["add_broadcast", "subadd_broadcast", "mul_broadcast",
      "guard_vector_constant", "guard_nonbroadcast"] do
    rows := rows.push {name, family := name}
  return rows

/-- The concrete source Broadcast axis attribute. -/
def axes : Bool → IndexMaps.BroadcastAxes 1 2
  | false => {values := #v[0], valid := by decide}
  | true => {values := #v[1], valid := by decide}

/-- Both square-array projections preserve the small extent exactly. -/
theorem extents (axis : Bool) :
    ∀ dimension, smallShape dimension = shape ((axes axis).decode dimension) := fun _ => rfl

/-- Project along the actual decoded dimension. -/
def broadcast {α : Type} (axis : Bool) (operand : Tensor smallShape α) : Tensor shape α :=
  reindex (IndexMaps.broadcastIndex (axes axis) (extents axis)) operand

/-- Scalar Broadcast carries the empty dimension array. -/
def scalarAxes : IndexMaps.BroadcastAxes 0 2 :=
  {values := #v[], valid := fun axis => Fin.elim0 axis}

theorem scalarExtents : ∀ axis, scalarShape axis = shape (scalarAxes.decode axis) :=
  fun axis => Fin.elim0 axis

def scalarBroadcast {α : Type} (operand : Tensor scalarShape α) : Tensor shape α :=
  reindex (IndexMaps.broadcastIndex scalarAxes scalarExtents) operand

/-- Coordinate labels for the independent nonuniform input vectors. -/
def offset (index : Index shape) : Nat := (index 0).val * 2 + (index 1).val

def left (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match offset index with
    | 0 => 0 | 1 => 1 | 2 => 2^width-1 | _ => 2^(width-1))

def right (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match offset index with
    | 0 => 2^width-1 | 1 => 2 | 2 => 3 | _ => 2^(width-1))

def shared (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match offset index with | 0 => 2^width-1 | 1 => 1 | 2 => 2 | _ => 3)

def small (width : Nat) : Tensor smallShape (BitVec width) := fun index =>
  BitVec.ofNat width (if (index 0).val = 0 then 2^width-1 else 3)

/-- Evaluate the actual before/after Tensor expressions; guard controls remain unchanged. -/
def evaluate (width : Nat) (recipe : Recipe) (replacement : Bool) : Tensor shape (BitVec width) :=
  let x := left width
  let y := right width
  let c := shared width
  let c1 : Tensor shape (BitVec width) := constant 2
  let c2 : Tensor shape (BitVec width) := constant 3
  let first : Tensor scalarShape (BitVec width) := constant 2
  let second : Tensor scalarShape (BitVec width) := constant 3
  let s1 := scalarBroadcast first
  let s2 := scalarBroadcast second
  if recipe.family = "factor" then
    if replacement then map₂ (· * ·) (map₂ (· + ·) x y) c
    else map₂ (· + ·) (OperandOrder.map₂ (· * ·) recipe.left x c)
      (OperandOrder.map₂ (· * ·) recipe.right y c)
  else if recipe.family = "product" then
    if replacement then map₂ (· * ·) x (map₂ (· * ·) c1 c2)
    else OperandOrder.map₂ (· * ·) recipe.outer (OperandOrder.map₂ (· * ·) recipe.left x c1) c2
  else if recipe.family = "four" then
    if replacement then map₂ (· * ·) (map₂ (· * ·) x y) (map₂ (· * ·) c1 c2)
    else OperandOrder.map₂ (· * ·) recipe.outer (OperandOrder.map₂ (· * ·) recipe.left x c1)
      (OperandOrder.map₂ (· * ·) recipe.right y c2)
  else if recipe.family = "move" then
    if replacement then map₂ (· * ·) x (broadcast recipe.axis (map₂ (· * ·) (small width)
      (constant 2)))
    else OperandOrder.map₂ (· * ·) recipe.outer (OperandOrder.map₂ (· * ·) recipe.left x c1)
      (broadcast recipe.axis (small width))
  else if recipe.family = "add_broadcast" then
    if replacement then map₂ (· + ·) x (scalarBroadcast (map₂ (· + ·) first second))
    else map₂ (· + ·) (map₂ (· + ·) x s1) s2
  else if recipe.family = "subadd_broadcast" then
    if replacement then map₂ (· - ·) (scalarBroadcast (map₂ (· + ·) first second)) x
    else map₂ (· + ·) (map₂ (· - ·) s1 x) s2
  else if recipe.family = "mul_broadcast" then
    if replacement then map₂ (· * ·) x (scalarBroadcast (map₂ (· * ·) first second))
    else map₂ (· * ·) (map₂ (· * ·) x s1) s2
  else if recipe.family = "guard_vector_constant" then
    map₂ (· * ·) (map₂ (· * ·) x (fun index => BitVec.ofNat width (offset index + 2)))
      (broadcast false (small width))
  else map₂ (· * ·) (map₂ (· * ·) x c1) y

/-- Observe all four cells in row-major order. -/
def observe {width : Nat} (tensor : Tensor shape (BitVec width)) : List Nat :=
  (List.finRange 4).map fun cell =>
    let coordinate : Index shape := fun axis =>
      ⟨if axis.val = 0 then cell.val / 2 else cell.val % 2, by dsimp [shape]; split <;> omega⟩
    (tensor coordinate).toNat

/-- Moving the scale must retain the original broadcast axis. -/
def movement (axis : Bool) : Recipe := {name := "move", family := "move", axis}

example : observe (evaluate 8 (movement false) true) ≠
    observe (evaluate 8 (movement true) true) := by decide

#eval show IO Unit from do
  for width in [8, 32, 64] do
    for recipe in recipes do
      let original := observe (evaluate width recipe false)
      let rewritten := observe (evaluate width recipe true)
      unless original == rewritten do throw (IO.userError "modular bridge disagreement")
      IO.println ("MODULAR_BRIDGE_MODEL width=" ++ toString width ++ " case=" ++ recipe.name ++
        " values=" ++ String.intercalate "," (rewritten.map toString))

end ModularBridgeControls
