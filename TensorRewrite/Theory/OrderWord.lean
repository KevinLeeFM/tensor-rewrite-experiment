module

public import TensorRewrite.Theory.OrderFamily
public import Mathlib.Data.BitVec

/-! Distinct signed and unsigned orders over actual modular-word bits. Arithmetic is not changed. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderFamily

/-- A word whose signedness selects its numerical comparison, separate from its stored bits. -/
structure Word (signed : Bool) (width : Nat) where
  bits : BitVec width
deriving DecidableEq, Repr

/-- Signed decoding uses two's complement; unsigned decoding uses the natural stored value. -/
def Word.decode {signed : Bool} {width : Nat} (value : Word signed width) : Int :=
  if signed then value.bits.toInt else Int.ofNat value.bits.toNat

instance {signed : Bool} {width : Nat} : Zero (Word signed width) := ⟨⟨0⟩⟩

instance {signed : Bool} {width : Nat} : LinearOrder (Word signed width) :=
  LinearOrder.lift' Word.decode (by
    intro x y equal
    cases x with | mk x =>
      cases y with | mk y =>
        congr
        cases signed
        · exact BitVec.eq_of_toNat_eq (Int.ofNat_inj.mp equal)
        · exact BitVec.toInt_inj.mp equal)

end TensorRewrite.Theory.OrderFamily
