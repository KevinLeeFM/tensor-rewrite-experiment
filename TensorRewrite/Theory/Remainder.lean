module

public import TensorRewrite.Pilot.Indexing
public import Init.Data.BitVec.Bitblast
public import Mathlib.Tactic

/-! Pure word remainder operators, explicit signed mask graph and bounded axis Iota values. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Remainder

open Pilot

/-- The actual signed Select/Negate/And replacement, with modular magnitude negation. -/
def signedMask {width : Nat} (value divisor : BitVec width) : BitVec width :=
  let negative := value.slt 0#width
  let magnitude := if negative then -value else value
  let masked := magnitude &&& (divisor - 1#width)
  if negative then -masked else masked

/-- A same-width Iota encodes the selected bounded logical coordinate. -/
def iota {rank : Nat} (shape : Shape rank) (axis : Fin rank) (width : Nat) :
    Tensor shape (BitVec width) := fun index => BitVec.ofNat width (index axis).val

/-- A mathematical signed remainder uses truncation toward zero, not Euclidean modulus. -/
def integer (value divisor : Int) : Int := value.tmod divisor

end TensorRewrite.Theory.Remainder
