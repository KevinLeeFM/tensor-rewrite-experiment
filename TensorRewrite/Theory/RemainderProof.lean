module

public import TensorRewrite.Theory.RemainderScalar

/-! Arbitrary-rank word tensor graphs and bounded Iota remainder transformations. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Remainder

open Pilot

/-- Exact truncating nested remainder lifts pointwise with the same divisor tensor. -/
theorem integer_nested_tensor {rank : Nat} {shape : Shape rank}
    (value divisor : Tensor shape Int) :
    Tensor.map₂ integer (Tensor.map₂ integer value divisor) divisor =
      Tensor.map₂ integer value divisor := by
  funext index
  exact integer_nested (value index) (divisor index)

/-- Unsigned word nesting preserves every tensor coordinate at arbitrary rank and width. -/
theorem unsigned_nested_tensor {rank width : Nat} {shape : Shape rank}
    (value divisor : Tensor shape (BitVec width)) :
    Tensor.map₂ (· % ·) (Tensor.map₂ (· % ·) value divisor) divisor =
      Tensor.map₂ (· % ·) value divisor := by
  funext index
  exact unsigned_nested (value index) (divisor index)

/-- Signed word nesting preserves the actual truncating word operator. -/
theorem signed_nested_tensor {rank width : Nat} {shape : Shape rank}
    (value divisor : Tensor shape (BitVec width)) :
    Tensor.map₂ BitVec.srem (Tensor.map₂ BitVec.srem value divisor) divisor =
      Tensor.map₂ BitVec.srem value divisor := by
  funext index
  exact signed_nested (value index) (divisor index)

/-- Unsigned masking uses the actual broadcast divisor-minus-one tensor. -/
theorem unsigned_mask_tensor {rank width exponent : Nat} {shape : Shape rank}
    (value : Tensor shape (BitVec width)) (fits : exponent < width) :
    Tensor.map₂ (· % ·) value (Tensor.constant (BitVec.ofNat width (2 ^ exponent))) =
      Tensor.map₂ (· &&& ·) value
        (Tensor.constant (BitVec.ofNat width (2 ^ exponent) - 1#width)) := by
  funext index
  exact unsigned_power_mask (value index) fits

/-- Signed masking retains both Selects and modular magnitude negation, even at signed minimum. -/
theorem signed_mask_tensor {rank width exponent : Nat} {shape : Shape rank}
    (value : Tensor shape (BitVec width)) (fits : exponent + 1 < width) :
    Tensor.map₂ BitVec.srem value (Tensor.constant (BitVec.ofNat width (2 ^ exponent))) =
      Tensor.map (fun x => signedMask x (BitVec.ofNat width (2 ^ exponent))) value := by
  funext index
  exact signed_power_mask (value index) fits

/-- A bounded unsigned Iota below the decoded divisor is unchanged, including empty axes. -/
theorem unsigned_iota {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (bound : shape axis ≤ divisor.toNat) :
    Tensor.map₂ (· % ·) (iota shape axis width) (Tensor.constant divisor) =
      iota shape axis width := by
  funext index
  apply BitVec.umod_eq_of_lt
  change (BitVec.ofNat width (index axis).val).toNat < divisor.toNat
  have less : (index axis).val < divisor.toNat := Nat.lt_of_lt_of_le (index axis).isLt bound
  have below : (index axis).val < 2 ^ width := Nat.lt_trans less divisor.isLt
  rw [BitVec.toNat_ofNat, Nat.mod_eq_of_lt below]
  exact less

/-- Signed Iota additionally uses a nonnegative decoded divisor, without discarding empty axes. -/
theorem signed_iota {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (nonnegative : divisor.msb = false)
    (bound : shape axis ≤ divisor.toNat) :
    Tensor.map₂ BitVec.srem (iota shape axis width) (Tensor.constant divisor) =
      iota shape axis width := by
  funext index
  have less : (index axis).val < divisor.toNat := Nat.lt_of_lt_of_le (index axis).isLt bound
  have divisorFits := BitVec.msb_eq_false_iff_two_mul_lt.mp nonnegative
  have fits : 2 * (index axis).val < 2 ^ width := by omega
  change (BitVec.ofNat width (index axis).val).srem divisor = _
  rw [BitVec.srem_eq, natural_msb_false fits, nonnegative]
  exact congrFun (unsigned_iota shape axis divisor bound) index

/-- Remove a rhs divisor addend when every actual unsigned Iota sum fits. -/
theorem unsigned_iota_offset_rhs {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (fits : ∀ index : Index shape,
      (index axis).val + divisor.toNat < 2 ^ width) :
    Tensor.map₂ (· % ·) (Tensor.map₂ (· + ·) (iota shape axis width) (Tensor.constant divisor))
      (Tensor.constant divisor) =
      Tensor.map₂ (· % ·) (iota shape axis width) (Tensor.constant divisor) := by
  funext index
  exact unsigned_offset divisor (fits index)

/-- The lhs addend orientation has the same explicitly checked unsigned range. -/
theorem unsigned_iota_offset_lhs {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (fits : ∀ index : Index shape,
      (index axis).val + divisor.toNat < 2 ^ width) :
    Tensor.map₂ (· % ·) (Tensor.map₂ (· + ·) (Tensor.constant divisor) (iota shape axis width))
      (Tensor.constant divisor) =
      Tensor.map₂ (· % ·) (iota shape axis width) (Tensor.constant divisor) := by
  funext index
  change (divisor + BitVec.ofNat width (index axis).val) % divisor = _
  rw [BitVec.add_comm]
  exact unsigned_offset divisor (fits index)

/-- Signed rhs offset removal requires the sum to fit the nonnegative signed half. -/
theorem signed_iota_offset_rhs {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (nonnegative : divisor.msb = false)
    (fits : ∀ index : Index shape, 2 * ((index axis).val + divisor.toNat) < 2 ^ width) :
    Tensor.map₂ BitVec.srem (Tensor.map₂ (· + ·) (iota shape axis width) (Tensor.constant divisor))
      (Tensor.constant divisor) =
      Tensor.map₂ BitVec.srem (iota shape axis width) (Tensor.constant divisor) := by
  funext index
  exact signed_offset divisor nonnegative (fits index)

/-- The lhs signed orientation preserves the same actual Select/range semantics. -/
theorem signed_iota_offset_lhs {rank width : Nat} (shape : Shape rank) (axis : Fin rank)
    (divisor : BitVec width) (nonnegative : divisor.msb = false)
    (fits : ∀ index : Index shape, 2 * ((index axis).val + divisor.toNat) < 2 ^ width) :
    Tensor.map₂ BitVec.srem (Tensor.map₂ (· + ·) (Tensor.constant divisor) (iota shape axis width))
      (Tensor.constant divisor) =
      Tensor.map₂ BitVec.srem (iota shape axis width) (Tensor.constant divisor) := by
  funext index
  change (divisor + BitVec.ofNat width (index axis).val).srem divisor = _
  rw [BitVec.add_comm]
  exact signed_offset divisor nonnegative (fits index)

end TensorRewrite.Theory.Remainder
