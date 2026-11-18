module
public import ScalarSpec
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarConcatSlice

private theorem locate_read {α : Type} (bs : List (List α)) (i : Nat)
    (h : i < bs.flatten.length) : ∃ b j, locate bs i = some (b,j) ∧
      j < b.length ∧ bs.flatten[i]? = b[j]? := by
  induction bs generalizing i with
  | nil => simp at h
  | cons b bs ih =>
    simp only [List.flatten_cons, List.length_append] at h
    by_cases hit : i < b.length
    · exact ⟨b,i,by simp [locate, hit],hit,List.getElem?_append_left hit⟩
    · obtain ⟨c,j,found,inside,read⟩ := ih (i-b.length) (by omega)
      exact ⟨c,j,by simpa [locate, hit] using found,inside,
        (List.getElem?_append_right (by omega : b.length ≤ i)).trans read⟩

private theorem single {α : Type} (xs : List α) (lo hi k : Nat)
    (size : extent lo hi k = 1) (valid : lo < xs.length) :
    slice xs lo hi k = [xs[lo]] := by
  simp [slice, size, List.range_one, List.getElem?_eq_getElem valid]

/-- Both effective-scalar replacements preserve the full result of the strided slice. -/
theorem verified : Case := by
  intro α bs lo hi k hk bound size
  have start : lo < hi := by
    by_cases ok : lo < hi
    · exact ok
    · simp [extent, ok] at size
  have valid : lo < bs.flatten.length := by omega
  obtain ⟨b,j,hit,inside,read⟩ := locate_read bs lo valid
  rw [List.getElem?_eq_getElem valid, List.getElem?_eq_getElem inside] at read
  have valEq := Option.some.inj read
  have localSize : extent j (j+1) k = 1 := by simp [extent]
  rw [single _ _ _ _ size valid]
  refine ⟨b,j,hit,inside,rfl,?_,?_⟩
  · rw [single _ _ _ _ localSize inside, valEq]
  · intro one
    rw [valEq]
    have zero : j = 0 := by omega
    subst j
    cases b with
    | nil => simp at inside
    | cons x xs =>
      have empty : xs = [] := List.length_eq_zero_iff.mp (by simpa using one)
      simp [empty]
end RevisedBenchmark.ScalarConcatSlice
#print axioms RevisedBenchmark.ScalarConcatSlice.verified
