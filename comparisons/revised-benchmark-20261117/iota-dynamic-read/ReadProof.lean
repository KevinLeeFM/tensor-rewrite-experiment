import ReadSpec
set_option autoImplicit false
namespace RevisedBenchmark.IotaRead

private theorem convert_id (s t : Bool) (x : Word) : convert s t x = x := by
  cases s <;> cases t <;> simp [convert, BitVec.ofNat_toNat]

private theorem cap_decode (s : Bool) (x : Word) :
    decode s x ≤ (signCap s : Int) := by
  cases s with
  | false =>
    have h := x.isLt
    change x.toNat < 4294967296 at h
    change (x.toNat : Int) ≤ 4294967295
    omega
  | true =>
    have h := BitVec.toInt_lt (x := x)
    change x.toInt < 2147483648 at h
    change x.toInt ≤ 2147483647
    omega

private theorem decode_high (s : Bool) (b : Nat) (bound : b ≤ signCap s) :
    decode s (BitVec.ofNat 32 b) = (b : Int) := by
  cases s with
  | false =>
    change b ≤ 4294967295 at bound
    change ((b % 4294967296 : Nat) : Int) = b
    rw [Nat.mod_eq_of_lt (by omega)]
  | true =>
    change b ≤ 2147483647 at bound
    unfold decode
    simp only [ite_true, BitVec.toInt, BitVec.toNat_ofNat]
    change (if 2 * (b % 4294967296) < 4294967296 then _ else _) = _
    rw [Nat.mod_eq_of_lt (by omega : b < 4294967296)]
    split <;> omega

private theorem reencode (s : Bool) (a : Word) (h : 0 ≤ decode s a) :
    BitVec.ofNat 32 (decode s a).toNat = a := by
  cases s with
  | false => simp [decode, BitVec.ofNat_toNat]
  | true =>
    change 0 ≤ a.toInt at h
    change BitVec.ofNat 32 a.toInt.toNat = a
    rw [← BitVec.ofInt_natCast, Int.toNat_of_nonneg h, BitVec.ofInt_toInt]

private theorem both (n : Nat) (valid : 0 < n) (s t : Bool) (a : Word) (m : Option Word) :
    original n valid s a m = replacement n s t a m := by
  funext j
  unfold original replacement
  rw [convert_id, decode_high _ _ (Nat.min_le_right _ _)]
  apply congrArg (scale m)
  change BitVec.ofNat 32 (min (decode s a).toNat (n-1)) = _
  have bound := cap_decode s a
  split
  · rename_i neg
    have hz : min (decode s a).toNat (n-1) = 0 := by omega
    rw [hz]
    rfl
  · rename_i nonneg
    split
    · rename_i above
      congr 1
      omega
    · rename_i below
      have h : min (decode s a).toNat (n-1) = (decode s a).toNat := by omega
      rw [h, reencode _ _ (by omega)]

theorem plain : Plain := fun n h s t a => both n h s t a none
theorem scaled : Scaled := fun n h s t a k => both n h s t a (some k)
example : Plain := plain
example : Scaled := scaled
#print axioms plain
#print axioms scaled
end RevisedBenchmark.IotaRead
