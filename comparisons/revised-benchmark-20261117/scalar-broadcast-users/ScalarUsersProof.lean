module
public import ScalarUsersSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarUsers
theorem sorted : SortFiber := by
  intro α n v le
  have perm := List.mergeSort_perm (List.replicate n v) le
  exact List.eq_replicate_iff.mpr ⟨perm.length_eq.trans (List.length_replicate ..),
    fun _ h => (List.mem_replicate.mp (perm.mem_iff.mp h)).2⟩
theorem reshaped : Reshaped := by unfold Reshaped; intros; rfl
theorem transposed : Transposed := by unfold Transposed; intros; rfl
theorem reversed : Reversed := by unfold Reversed; intros; rfl
theorem sliced : Sliced := by unfold Sliced; intros; rfl
theorem dynamicSliced : DynamicSliced := by unfold DynamicSliced; intros; rfl

example : ([7,7,7] : List Nat).mergeSort (fun _ _ => false) = [7,7,7] := sorted Nat 3 7 _
example : ([7,8,7] : List Nat).mergeSort (fun x y => decide (x ≤ y)) ≠ [7,7,7] := by
  intro wrong
  have member := (List.mergeSort_perm ([7,8,7] : List Nat) (fun x y => decide (x ≤ y))).mem_iff.mpr
    (show 8 ∈ ([7,8,7] : List Nat) by decide)
  rw [wrong] at member
  exact (by decide : 8 ∉ ([7,7,7] : List Nat)) member
example : (List.replicate 0 7).mergeSort (fun _ _ => true) = [] := sorted Nat 0 7 _
#print axioms sorted
#print axioms reshaped
#print axioms transposed
#print axioms reversed
#print axioms sliced
#print axioms dynamicSliced
end RevisedBenchmark.ScalarUsers
