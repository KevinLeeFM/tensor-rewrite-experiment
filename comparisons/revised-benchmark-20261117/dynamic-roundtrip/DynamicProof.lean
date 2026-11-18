import DynamicSpec
set_option autoImplicit false
namespace RevisedBenchmark.Roundtrip

private theorem signedSize (n : Nat) (h : n < 2^31) : (BitVec.ofNat 32 n).toInt = (n : Int) := by
  simp only [BitVec.toInt, BitVec.toNat_ofNat]
  change (if 2*(n%4294967296) < 4294967296 then _ else _) = _
  change n < 2147483648 at h
  rw [Nat.mod_eq_of_lt (by omega : n < 4294967296)]
  split <;> omega

theorem verified : Case := by
  intro A cap x fits hs clamped hb padding
  unfold padToStatic visibleSize sliceToDynamic
  simp only [signedSize _ hs]
  cases clamped with
  | false => simp
  | true =>
    rw [signedSize _ (hb rfl)]
    have hle : (x.length : Int) ≤ cap := by exact_mod_cast fits
    simp [Int.min_eq_left hle, Int.max_eq_right]
example : Case := verified
#print axioms verified
end RevisedBenchmark.Roundtrip
