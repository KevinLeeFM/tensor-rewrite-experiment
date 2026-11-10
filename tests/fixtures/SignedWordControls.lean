import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Tensor

namespace SignedWordControls

/-- The source boundary vectors have six cells. -/
def shape : Shape 1 := fun _ => 6

/-- Binary operations computed in the evaluator's signed 64-bit intermediate type. -/
inductive Operation where
  | add | subtract | multiply
  deriving Repr

/-- Encode signed inputs, compute as unsigned 64-bit words, reinterpret and narrow. -/
def calculate (width : Nat) (operation : Operation) (x y : BitVec width) : BitVec width :=
  let lhs := BitVec.ofInt 64 x.toInt
  let rhs := BitVec.ofInt 64 y.toInt
  let result := match operation with
    | .add => lhs + rhs
    | .subtract => lhs - rhs
    | .multiply => lhs * rhs
  BitVec.ofInt width result.toInt

/-- Pointwise evaluation retains the intermediate narrowing at each HLO node. -/
def binary (width : Nat) (operation : Operation) :
    Tensor shape (BitVec width) → Tensor shape (BitVec width) → Tensor shape (BitVec width) :=
  map₂ (calculate width operation)

/-- Maximum/minimum signed values, minus one and adjacent boundary words. -/
def left (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 2^(width-1)-1 | 1 => 2^(width-1) | 2 => 2^width-1
    | 3 => 2^(width-1)+1 | 4 => 2^(width-1)-2 | _ => 0)

def right (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 1 | 1 => 2^width-1 | 2 => 2 | 3 => 2^(width-1)-1 | 4 => 3 | _ => 2^(width-1))

def shared (width : Nat) : Tensor shape (BitVec width) := fun index =>
  BitVec.ofNat width (match (index 0).val with
    | 0 => 2^width-1 | 1 => 2 | 2 => 3 | 3 => 2^(width-1) | 4 => 2^(width-1)-1 | _ => 1)

/-- Original and replacement expressions for the signed native recipes. -/
def evaluate (width : Nat) (name : String) (replacement : Bool) : Tensor shape (BitVec width) :=
  let x := left width
  let y := right width
  let c := shared width
  if name = "add_zero" then
    if replacement then x else binary width .add x (constant 0)
  else if name = "add_constant" then
    if replacement then binary width .add x (constant 2) else binary width .add (constant 2) x
  else if name = "add_assoc" then
    if replacement then binary width .add x (binary width .add (constant 2) (constant 3))
    else binary width .add (binary width .add x (constant 2)) (constant 3)
  else if name = "factor" then
    if replacement then binary width .multiply (binary width .add x y) c
    else binary width .add (binary width .multiply x c) (binary width .multiply y c)
  else if name = "mul_zero" then
    if replacement then constant 0 else binary width .multiply x (constant 0)
  else if name = "mul_one" then
    if replacement then x else binary width .multiply x (constant 1)
  else if name = "mul_neg_neg" then
    if replacement then binary width .multiply x y
    else binary width .multiply (map Neg.neg x) (map Neg.neg y)
  else if name = "sub_self" then
    if replacement then constant 0 else binary width .subtract x x
  else if name = "sub_zero" then
    if replacement then x else binary width .subtract x (constant 0)
  else if name = "sub_constant" then
    if replacement then binary width .add x (map Neg.neg (constant 3))
    else binary width .subtract x (constant 3)
  else if name = "neg_neg" then
    if replacement then x else map Neg.neg (map Neg.neg x)
  else
    if replacement then binary width .multiply (binary width .multiply x y)
      (binary width .multiply (constant 2) (constant 3))
    else binary width .multiply (binary width .multiply x (constant 2))
      (binary width .multiply y (constant 3))

def words {width : Nat} (tensor : Tensor shape (BitVec width)) : List Nat :=
  List.ofFn fun cell : Fin 6 => (tensor (fun _ => cell)).toNat

def signed {width : Nat} (tensor : Tensor shape (BitVec width)) : List Int :=
  List.ofFn fun cell : Fin 6 => (tensor (fun _ => cell)).toInt

-- The width bound is essential; a narrower intermediate can discard input bits.
example : (BitVec.ofInt 4 16).setWidth 8 ≠ BitVec.ofInt 8 16 := by decide

-- At the minimum signed value, modular negation is not unbounded Int negation.
example : (-(BitVec.ofInt 8 (-128))).toInt = -128 := by rfl

#eval show IO Unit from do
  for width in [8, 16, 32, 64] do
    for name in ["add_zero", "add_constant", "add_assoc", "factor", "mul_zero", "mul_one",
        "mul_neg_neg", "four_factors", "sub_self", "sub_zero", "sub_constant", "neg_neg"] do
      let original := evaluate width name false
      let rewritten := evaluate width name true
      unless words original == words rewritten && signed original == signed rewritten do
        throw (IO.userError "signed promotion probe disagreement")
      IO.println ("SIGNED_WORD_MODEL width=" ++ toString width ++ " case=" ++ name ++
        " values=" ++ String.intercalate "," ((words rewritten).map toString) ++
        " signed=" ++ String.intercalate "," ((signed rewritten).map toString))

end SignedWordControls
