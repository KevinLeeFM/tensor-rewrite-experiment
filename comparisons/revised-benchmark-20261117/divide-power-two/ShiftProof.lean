import ShiftSpec
set_option autoImplicit false
namespace RevisedBenchmark.DividePowerTwo
open TensorRewrite.Pilot Tensor

private theorem divide_word {w : Nat} (a b : BitVec w)
    (power : ∃ k : Nat, b.toNat = 2 ^ k) : a.udiv b = shifted a b := by
  obtain ⟨k,h⟩ := power
  have bound : k < 2 ^ w :=
    Nat.lt_trans (Nat.lt_two_pow_self (n := k)) (h ▸ b.isLt)
  have count : (shiftCount b).toNat = k := by
    simp only [shiftCount, h, Nat.log2_two_pow, BitVec.toNat_ofNat, Nat.mod_eq_of_lt bound]
  apply BitVec.eq_of_toNat_eq
  change a.toNat / b.toNat = (a.ushiftRight (shiftCount b).toNat).toNat
  rw [count, h]
  change a.toNat / 2 ^ k = a.toNat >>> k
  exact (Nat.shiftRight_eq_div_pow _ _).symm

theorem unsignedCase : UnsignedCase := by
  intro r w s b power x
  exact funext fun i => divide_word (x i) b power

theorem signedCase : SignedCase := by
  intro r w s b positive power x
  have pos : b.msb = false := by
    rw [BitVec.msb_eq_toInt]
    simp [Int.not_lt.mpr (Int.le_of_lt positive)]
  funext i
  change (x i).sdiv b = signedShift (x i) b
  have neg : (x i).slt 0 = (x i).msb := BitVec.slt_zero_eq_msb
  cases sign : (x i).msb <;>
    simp only [BitVec.sdiv, pos, sign, signedShift, neg,
      Bool.false_eq_true, ite_false, ite_true, divide_word _ b power] <;> rfl

example : UnsignedCase := unsignedCase
example : SignedCase := signedCase
#print axioms unsignedCase
#print axioms signedCase
end RevisedBenchmark.DividePowerTwo
