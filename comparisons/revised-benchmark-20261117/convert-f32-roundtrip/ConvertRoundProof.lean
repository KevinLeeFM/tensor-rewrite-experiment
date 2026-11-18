import ConvertRoundSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvertRound
open RevisedBenchmark.RadixIota

private theorem exactNat (n : Nat) (h : n ≤ 2^24) : r32 n = n := by
  by_cases top : n = 2^24
  · subst n; decide
  by_cases zero : n = 0
  · subst n; decide
  have log : n.log2 < 24 := (Nat.log2_lt zero).2 (by omega)
  have exp : n.log2 - 23 = 0 := by omega
  simp [r32,exp,Nat.mod_one]

private theorem exactInt (x : Int) (lo : -16777216 ≤ x) (hi : x ≤ 16777216) :
    encode32 x = x := by
  unfold encode32
  split
  · rw [exactNat _ (by omega),Int.toNat_of_nonneg (by omega)]; omega
  · rw [exactNat _ (by omega),Int.toNat_of_nonneg (by omega)]

private theorem powerBound (k : Nat) (h : k ≤ 24) : 2^k ≤ 16777216 :=
  Nat.pow_le_pow_right (by decide : 0 < 2) h
private theorem powerLarge (k : Nat) (h : 25 ≤ k) : 33554432 ≤ 2^k :=
  Nat.pow_le_pow_right (by decide : 0 < 2) h

theorem verified : Case := by
  intro s t _
  constructor
  · intro all
    apply Classical.byContradiction
    intro large
    have bounds : low s t ≤ 16777216 ∧ 16777217 ≤ high s t := by
      cases s <;> simp only [low,high,Bool.false_eq_true,ite_false,ite_true] at large ⊢
      · have := powerLarge (t+1) (by omega); omega
      · have := powerLarge t (by omega); omega
    have h := all 16777217 (by omega) bounds.2
    have val : encode32 16777217 = 16777216 := by decide
    unfold back at h
    rw [val, Int.min_eq_right (by omega), Int.max_eq_right bounds.1] at h
    omega
  · intro width x hx hx'
    have bounds : -16777216 ≤ low s t ∧ high s t ≤ 16777216 := by
      cases s <;> simp only [low,high,Bool.false_eq_true,ite_false,ite_true] at width ⊢
      · have := powerBound (t+1) width; omega
      · have := powerBound t width; omega
    rw [back,exactInt x (by omega) (by omega),Int.min_eq_right hx',Int.max_eq_right hx]
#print axioms verified
end RevisedBenchmark.ConvertRound
