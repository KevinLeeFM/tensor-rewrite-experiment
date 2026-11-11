module

public import TensorRewrite.Theory.Remainder

/-! Library-derived mask and unsigned/signed range facts, retaining modular word behavior. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Remainder

/-- A represented power of two is nonzero exactly below the selected word width. -/
theorem power_toNat {width exponent : Nat} (fits : exponent < width) :
    (BitVec.ofNat width (2 ^ exponent)).toNat = 2 ^ exponent := by
  rw [BitVec.toNat_ofNat, Nat.mod_eq_of_lt (Nat.pow_lt_pow_of_lt (by decide) fits)]

/-- Subtracting one from a represented positive power gives the actual low-bit mask. -/
theorem power_mask {width exponent : Nat} (fits : exponent < width) :
    BitVec.ofNat width (2 ^ exponent) - 1#width =
      BitVec.ofNat width (2 ^ exponent - 1) := by
  apply BitVec.ofNat_sub_ofNat_of_le
  · have widthPositive : 0 < width := by omega
    exact Nat.one_lt_two_pow (by omega)
  · exact Nat.one_le_pow _ _ (by decide)

/-- A natural word is nonnegative in signed interpretation when twice its value fits. -/
theorem natural_msb_false {width value : Nat} (fits : 2 * value < 2 ^ width) :
    (BitVec.ofNat width value).msb = false := by
  apply BitVec.msb_eq_false_iff_two_mul_lt.mpr
  have below : value < 2 ^ width := by omega
  simpa only [BitVec.toNat_ofNat, Nat.mod_eq_of_lt below] using fits

/-- The admitted positive signed powers exclude the sign bit. -/
theorem signed_power_msb {width exponent : Nat} (fits : exponent + 1 < width) :
    (BitVec.ofNat width (2 ^ exponent)).msb = false := by
  apply natural_msb_false
  calc
    2 * 2 ^ exponent = 2 ^ (exponent + 1) := by rw [Nat.pow_succ, Nat.mul_comm]
    _ < 2 ^ width := Nat.pow_lt_pow_of_lt (by decide) fits

/-- Unsigned no-overflow addition retains the exact natural sum before taking remainder. -/
theorem natural_add_toNat {width value : Nat} (divisor : BitVec width)
    (fits : value + divisor.toNat < 2 ^ width) :
    (BitVec.ofNat width value + divisor).toNat = value + divisor.toNat := by
  have below : value < 2 ^ width := by omega
  simp only [BitVec.toNat_add, BitVec.toNat_ofNat, Nat.mod_eq_of_lt below,
    Nat.mod_eq_of_lt fits]

/-- A stronger signed no-overflow bound keeps both Iota and its offset sum nonnegative. -/
theorem natural_add_msb_false {width value : Nat} (divisor : BitVec width)
    (fits : 2 * (value + divisor.toNat) < 2 ^ width) :
    (BitVec.ofNat width value + divisor).msb = false := by
  apply BitVec.msb_eq_false_iff_two_mul_lt.mpr
  have below : value + divisor.toNat < 2 ^ width := by omega
  rw [natural_add_toNat divisor below]
  exact fits

end TensorRewrite.Theory.Remainder
