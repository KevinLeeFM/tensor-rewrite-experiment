import IDSpec
namespace RevisedBenchmark.IDClamp
theorem verified : Goal := by
  intro k r p hi test x
  have cond : bound k r p ≤ hi.toNat + 1 := by
    simpa [eligible] using (Bool.and_eq_true_iff.mp test).2
  have h := x.isLt
  have fits := hi.isLt
  have below : x.val < 2^32 := by omega
  have clipped : x.val ≤ hi.toNat := by omega
  simp [original, BitVec.toNat_ofNat, Nat.mod_eq_of_lt below, Nat.min_eq_left clipped]
#print axioms verified
end RevisedBenchmark.IDClamp
