module
public import GatherSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.GatherExact
open TensorRewrite.Pilot.ReducerIndex.GatherLiterals

private theorem literal {k p : Nat} (h : p < 2^k) :
    (BitVec.ofNat (k+1) p).toInt = (p : Int) := by
  have room : p < 2^(k+1) := by rw [Nat.pow_succ]; omega
  simp only [BitVec.toInt, BitVec.toNat_ofNat, Nat.mod_eq_of_lt room]
  rw [Nat.pow_succ]
  rw [ite_eq_left (by omega)]

private theorem firstNegative (k : Nat) :
    (BitVec.ofNat (k+1) (2^k)).toInt ≤ 0 := by
  have pos : 0 < 2^k := Nat.two_pow_pos _
  have room : 2^k < 2^(k+1) := by rw [Nat.pow_succ]; omega
  simp only [BitVec.toInt, BitVec.toNat_ofNat, Nat.mod_eq_of_lt room]
  rw [Nat.pow_succ]
  rw [ite_eq_right (by omega)]
  omega

private theorem step {w : Nat} (n : Nat) (i : BitVec w) :
    selectedIndex (n+1) i =
      if (BitVec.ofNat w n).toInt ≤ i.toInt then n else selectedIndex n i := by
  simp [selectedIndex, List.range_succ, List.foldl_append, choose]

/-- Once signed zero has selected the first narrowed negative literal,
    a later step can only leave that position or choose a later one. -/
private theorem persists (k more : Nat) :
    2^k ≤ selectedIndex (2^k + 1 + more) (0 : BitVec (k+1)) := by
  induction more with
  | zero =>
    rw [Nat.add_zero, step, ite_eq_left (by simpa using firstNegative k)]
    exact Nat.le_refl _
  | succ more ih =>
    rw [← Nat.add_assoc, step]
    split <;> omega

theorem correct : Goal := by
  intro k extent
  constructor
  · intro all
    by_cases fits : extent ≤ 2^k
    · exact fits
    exfalso
    have h : extent = 2^k + 1 + (extent - (2^k+1)) := by omega
    have wrong := persists k (extent - (2^k+1))
    rw [← h, all] at wrong
    simp [originalIndex] at wrong
  · intro fits i
    apply selectedIndex_eq_original
    intro p hp
    exact literal (Nat.lt_of_lt_of_le hp fits)
#print axioms correct
end RevisedBenchmark.GatherExact
