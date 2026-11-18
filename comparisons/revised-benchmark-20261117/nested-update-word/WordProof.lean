import WordSpec
namespace RevisedBenchmark.NestedUpdateWord

theorem refuted : ¬ Case := by
  intro claimed
  have h := congrFun (claimed (fun _ => 0) (fun _ => 7) (BitVec.ofNat 64 9223372036854775808) 1) 1
  have lhs : install (fun _ : Fin 10 => 0) (install (readWindow 6 (by decide) (fun _ : Fin 10 => 0) (BitVec.ofNat 64 9223372036854775808)) (fun _ : Fin 2 => 7) 1) (BitVec.ofNat 64 9223372036854775808) 1 = 7 := by decide
  have rhs : install (fun _ : Fin 10 => 0) (fun _ : Fin 2 => 7) (typedStart 4 (BitVec.ofNat 64 9223372036854775808) + typedStart 4 1) 1 = 0 := by decide
  exact (by decide : (7 : Nat) ≠ 0) (lhs.symm.trans (h.trans rhs))

#print axioms refuted
end RevisedBenchmark.NestedUpdateWord
