module

public import TensorRewrite.Theory.PrefixWindowSampling
public import TensorRewrite.Pilot.ModularArithmetic

/-! Repeated modular addition and exact unsigned/signed count conversion domains. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

/-- Repeated word addition is modular multiplication by the count, retaining any initializer. -/
theorem word_replicate_fold (width count : Nat) (initial value : BitVec width) :
    (List.replicate count value).foldl (· + ·) initial =
      initial + BitVec.ofNat width count * value := by
  induction count generalizing initial with
  | zero => simp [BitVec.zero_mul, BitVec.add_zero]
  | succ count ih =>
    rw [List.replicate_succ, List.foldl_cons, ih]
    rw [BitVec.ofNat_add, BitVec.add_mul, BitVec.one_mul]
    rw [BitVec.add_assoc, BitVec.add_comm value (BitVec.ofNat width count * value),
      ← BitVec.add_assoc]

/-- Unsigned conversion preserves a natural count exactly iff it fits the word width. -/
theorem unsigned_count_exact_iff (width count : Nat) :
    (BitVec.ofNat width count).toNat = count ↔ count < 2 ^ width := by
  rw [BitVec.toNat_ofNat]
  constructor
  · intro same
    have bound := Nat.mod_lt count (Nat.two_pow_pos width)
    omega
  · exact Nat.mod_eq_of_lt

/-- Signed interpretation preserves a nonnegative count exactly iff it fits the positive half. -/
theorem signed_count_exact_iff (width count : Nat) :
    (BitVec.ofNat width count).toInt = (count : Int) ↔ 2 * count < 2 ^ width := by
  have bound := Nat.mod_lt count (Nat.two_pow_pos width)
  constructor
  · intro same
    rw [BitVec.toInt_eq_toNat_cond, BitVec.toNat_ofNat] at same
    split at same <;> omega
  · intro fits
    have below : count < 2 ^ width := by omega
    simp only [BitVec.toInt_eq_toNat_cond, BitVec.toNat_ofNat,
      Nat.mod_eq_of_lt below, fits, ite_true]

end TensorRewrite.Theory.PrefixWindow
