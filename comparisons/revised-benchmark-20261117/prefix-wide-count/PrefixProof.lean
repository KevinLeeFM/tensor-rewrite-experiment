import PrefixSpec
namespace RevisedBenchmark.WideCount
/-- Std-only specialization of PrefixWindowArithmetic.word_replicate_fold.
It permits a symbolic proof without constructing the witness tensor. -/
theorem folded (n : Nat) (z x : BitVec 64) :
    (List.replicate n x).foldl (· + ·) z = z + BitVec.ofNat 64 n * x := by
  induction n generalizing z with
  | zero => simp [BitVec.zero_mul, BitVec.add_zero]
  | succ n ih =>
    rw [List.replicate_succ, List.foldl_cons, ih, BitVec.ofNat_add,
      BitVec.add_mul, BitVec.one_mul, BitVec.add_assoc,
      BitVec.add_comm x (BitVec.ofNat 64 n * x), ← BitVec.add_assoc]
theorem originalCount (r : Nat) : original 1 r = BitVec.ofNat 64 (r+1) := by
  simp [original, folded, BitVec.mul_one, BitVec.zero_add]
theorem refuted : ¬ Goal := by
  intro h
  let r : Fin 2147483648 := ⟨2147483647, by decide⟩
  have eq := h 2147483648 (by decide) r 1
  rw [originalCount] at eq
  exact (by decide : BitVec.ofNat 64 (r.val+1) ≠ replacement 1 r.val) eq
#print axioms refuted
end RevisedBenchmark.WideCount
