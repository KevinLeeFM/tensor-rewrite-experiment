module
public import Spec
@[expose] public section
set_option autoImplicit false
namespace Heldout.RemainderCast

private theorem scalar_remainder_cast {narrow wide : Nat} (h : narrow ≤ wide)
    (a b : BitVec narrow) :
    ((a.setWidth wide % b.setWidth wide).setWidth narrow) = a % b := by
  apply BitVec.eq_of_toNat_eq
  have hpow : 2 ^ narrow ≤ 2 ^ wide :=
    Nat.pow_le_pow_right (by omega : 2 > 0) h
  have ha : a.toNat % 2 ^ wide = a.toNat :=
    Nat.mod_eq_of_lt (Nat.lt_of_lt_of_le a.isLt hpow)
  have hb : b.toNat % 2 ^ wide = b.toNat :=
    Nat.mod_eq_of_lt (Nat.lt_of_lt_of_le b.isLt hpow)
  have hrem : a.toNat % b.toNat < 2 ^ narrow := by
    by_cases hz : b.toNat = 0
    · simp [hz]
      exact a.isLt
    · have hlt := Nat.mod_lt a.toNat (Nat.pos_of_ne_zero hz)
      omega
  simp only [BitVec.toNat_setWidth, BitVec.toNat_umod, ha, hb]
  exact Nat.mod_eq_of_lt hrem

/-- The frozen conversion/remainder/conversion graph equals narrow remainder. -/
theorem goal_proof : Goal := by
  intro rank narrow wide shape h left right
  funext i
  exact scalar_remainder_cast h (left i) (right i)

end Heldout.RemainderCast
#print axioms Heldout.RemainderCast.goal_proof
