import FoldSpec
namespace RevisedBenchmark.MixedTapCount

-- Width-polymorphic instance of PrefixWindow.word_replicate_fold.
theorem repeatSum (w n : Nat) (v z : BitVec w) :
    (List.replicate n v).foldl (·+·) z = z + BitVec.ofNat w n * v := by
  induction n generalizing z with
  | zero => simp [BitVec.zero_mul, BitVec.add_zero]
  | succ n ih =>
    rw [List.replicate_succ, List.foldl_cons, ih, BitVec.ofNat_add,
      BitVec.add_mul, BitVec.one_mul, BitVec.add_assoc,
      BitVec.add_comm v (BitVec.ofNat w n * v), ← BitVec.add_assoc]

def value (k : Kind) : Fin (bound k) := ⟨255, by cases k <;> decide⟩

theorem foldOld (a b : Kind) (rev : Bool) (n : Nat) :
    old rev n (value a) (value b) =
      BitVec.ofNat 32 (min (BitVec.ofNat 64 n * 65025#64).toNat 4294967295) := by
  cases a <;> cases b <;> cases rev <;>
    simp [old, kernelTerms, repeatSum, BitVec.zero_add, widen, value] <;> rfl

theorem foldNew (a b : Kind) (rev : Bool) (n : Nat) :
    newValue rev n (value a) (value b) = BitVec.ofNat 32 n * 65025#32 := by
  cases a <;> cases b <;> cases rev <;>
    simp [newValue,kernelTerms,repeatSum,BitVec.zero_add,widen,value]

theorem refuted (a b : Kind) (rev : Bool) : ¬ Claim a b rev := by
  intro keep
  have h := keep 66052 (by decide) (value a) (value b)
  rw [foldOld,foldNew] at h
  exact (by decide : BitVec.ofNat 32 (min (BitVec.ofNat 64 66052 * 65025#64).toNat 4294967295)
    ≠ BitVec.ofNat 32 66052 * 65025#32) h
#print axioms refuted
end RevisedBenchmark.MixedTapCount
