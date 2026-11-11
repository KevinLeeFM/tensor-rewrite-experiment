module

public import TensorRewrite.Theory.RemainderLemmas

/-! Exact truncating and all-width word remainder laws with explicit representability domains. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Remainder

/-- Nested exact truncating remainder is idempotent, including the total zero-divisor model. -/
theorem integer_nested (value divisor : Int) :
    integer (integer value divisor) divisor = integer value divisor :=
  Int.tmod_tmod value divisor

/-- Unsigned word remainder is idempotent at every width and divisor. -/
theorem unsigned_nested {width : Nat} (value divisor : BitVec width) :
    (value % divisor) % divisor = value % divisor := by
  apply BitVec.eq_of_toNat_eq
  simp only [BitVec.toNat_umod, Nat.mod_mod]

/-- Signed word remainder is idempotent, including signed minimum and the degenerate width zero. -/
theorem signed_nested {width : Nat} (value divisor : BitVec width) :
    (value.srem divisor).srem divisor = value.srem divisor := by
  apply BitVec.eq_of_toInt_eq
  simp only [BitVec.toInt_srem, Int.tmod_tmod]

/-- An unsigned represented power-of-two remainder equals the actual bitwise low-mask graph. -/
theorem unsigned_power_mask {width exponent : Nat} (value : BitVec width)
    (fits : exponent < width) :
    value % BitVec.ofNat width (2 ^ exponent) =
      value &&& (BitVec.ofNat width (2 ^ exponent) - 1#width) := by
  rw [power_mask fits]
  apply BitVec.eq_of_toNat_eq
  rw [BitVec.toNat_umod, power_toNat fits, BitVec.toNat_and, BitVec.toNat_ofNat]
  have below : (2 ^ exponent - 1 : Nat) < 2 ^ width := by
    have bound : 2 ^ exponent < 2 ^ width :=
      Nat.pow_lt_pow_of_lt (by decide) fits
    exact Nat.lt_of_le_of_lt (Nat.sub_le _ _) bound
  rw [Nat.mod_eq_of_lt below, Nat.and_two_pow_sub_one_eq_mod]

/-- Signed power masking uses modular negation, so signed minimum needs no exceptional repair. -/
theorem signed_power_mask {width exponent : Nat} (value : BitVec width)
    (fits : exponent + 1 < width) :
    value.srem (BitVec.ofNat width (2 ^ exponent)) =
      signedMask value (BitVec.ofNat width (2 ^ exponent)) := by
  have unsignedFits : exponent < width := by omega
  rw [BitVec.srem_eq, signed_power_msb fits]
  cases negative : value.msb <;>
    simp only [negative, signedMask, BitVec.slt_zero_eq_msb, Bool.false_eq_true, ite_false,
      ite_true, unsigned_power_mask _ unsignedFits]

/-- Adding a divisor before unsigned remainder is sound when actual word addition does not wrap. -/
theorem unsigned_offset {width value : Nat} (divisor : BitVec width)
    (fits : value + divisor.toNat < 2 ^ width) :
    (BitVec.ofNat width value + divisor) % divisor = BitVec.ofNat width value % divisor := by
  apply BitVec.eq_of_toNat_eq
  have below : value < 2 ^ width := by omega
  rw [BitVec.toNat_umod, natural_add_toNat divisor fits, BitVec.toNat_umod,
    BitVec.toNat_ofNat, Nat.mod_eq_of_lt below, Nat.add_mod_right]

/-- Signed offset removal additionally keeps Iota and the sum on the nonnegative signed side. -/
theorem signed_offset {width value : Nat} (divisor : BitVec width)
    (nonnegative : divisor.msb = false) (fits : 2 * (value + divisor.toNat) < 2 ^ width) :
    (BitVec.ofNat width value + divisor).srem divisor =
      (BitVec.ofNat width value).srem divisor := by
  have inputFits : 2 * value < 2 ^ width := by omega
  have unsignedFits : value + divisor.toNat < 2 ^ width := by omega
  simp only [BitVec.srem_eq, nonnegative, natural_msb_false inputFits,
    natural_add_msb_false divisor fits]
  exact unsigned_offset divisor unsignedFits

end TensorRewrite.Theory.Remainder
