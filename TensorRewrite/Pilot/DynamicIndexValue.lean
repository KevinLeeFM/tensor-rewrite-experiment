module

public import Std

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.DynamicIndex

/-- The decoded mathematical value of a signed finite-width start index. -/
def signedValue {width : Nat} (bits : BitVec width) : Int := bits.toInt

/-- The decoded mathematical value of an unsigned finite-width start index. -/
def unsignedValue {width : Nat} (bits : BitVec width) : Int := bits.toNat

/-- The u64-to-s64 conversion observed in this pinned evaluator on the test host. -/
def evaluatorUnsigned64 (bits : BitVec 64) : Int := bits.toInt

/-- Clamp an index so a width-sized slice fits inside the input extent. -/
def clampStart (extent width : Nat) (start : Int) : Int :=
  min (max 0 start) ((extent : Int) - (width : Int))

end TensorRewrite.Pilot.DynamicIndex
