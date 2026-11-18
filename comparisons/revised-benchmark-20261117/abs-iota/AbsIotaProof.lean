import AbsIotaSpec
namespace RevisedBenchmark.AbsIota

private theorem fixedPrefix (k q : Nat) (hq : q ≤ 2^(k+1)) :
    (BitVec.ofNat (k+2) q).abs = BitVec.ofNat (k+2) q := by
  let x := BitVec.ofNat (k+2) q
  change x.abs = x
  have double : 2^(k+2) = 2^(k+1)*2 := Nat.pow_succ 2 (k+1)
  have pos := Nat.two_pow_pos (k+1)
  have repr : x.toNat = q := by
    rw [BitVec.toNat_ofNat]; exact Nat.mod_eq_of_lt (by omega)
  by_cases lt : q < 2^(k+1)
  · have sign := (BitVec.msb_eq_false_iff_two_mul_lt (x := x)).2 (by omega)
    simp [BitVec.abs, sign]
  · have selfNeg : -x = x := by
      apply BitVec.eq_of_toNat_eq
      rw [BitVec.toNat_neg, repr, Nat.mod_eq_of_lt (by omega)]
      omega
    simp [BitVec.abs, selfNeg]

private theorem firstFailure (k : Nat) :
    (BitVec.ofNat (k+2) (2^(k+1)+1)).abs ≠ BitVec.ofNat (k+2) (2^(k+1)+1) := by
  let x := BitVec.ofNat (k+2) (2^(k+1)+1)
  change x.abs ≠ x
  have double : 2^(k+2) = 2^(k+1)*2 := Nat.pow_succ 2 (k+1)
  have half := Nat.pow_succ 2 k
  have pos := Nat.two_pow_pos k
  have repr : x.toNat = 2^(k+1)+1 := by
    rw [BitVec.toNat_ofNat]; exact Nat.mod_eq_of_lt (by omega)
  have sign : x.msb = true := by
    cases h : x.msb with
    | true => rfl
    | false => have := BitVec.msb_eq_false_iff_two_mul_lt.mp h; omega
  simp only [BitVec.abs, sign, ite_true]
  intro h
  have bad := congrArg BitVec.toNat h
  change (-x).toNat = x.toNat at bad
  rw [BitVec.toNat_neg, repr, Nat.mod_eq_of_lt (by omega)] at bad
  omega

theorem verified : Case := by
  intro k n C
  constructor
  · intro h
    by_cases bound : n ≤ 2^(k+1)+1
    · exact Or.inr bound
    · left
      intro c
      let i : Fin n := ⟨2^(k+1)+1, by omega⟩
      exact firstFailure k (congrFun (congrFun h i) c)
  · rintro (empty | bound) <;> funext i c
    · exact (empty c).elim
    · exact fixedPrefix k i (by have := i.isLt; omega)

example : Case := verified
#print axioms verified
end RevisedBenchmark.AbsIota
