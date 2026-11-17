module
public import ClassificationSpec
public import DynamicProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicSort

/-- A guard firing on an ordinary fixed or upper-bound descriptor forces a
    list of length at most one. Every comparator then gives the same list. -/
private theorem trivialList {α : Type} (d : Dim) (finite : d ≠ .unbounded)
    (xs : List α) (adm : d.admits xs.length) (guard : forward d)
    (le : α → α → Bool) : xs.mergeSort le = xs := by
  have h : xs.length ≤ 1 := by
    cases d with
    | fixed n => simp [Dim.admits] at adm; simp [forward, Dim.stored] at guard; omega
    | bounded n => simp [Dim.admits] at adm; simp [forward, Dim.stored] at guard; omega
    | unbounded => exact False.elim (finite rfl)
  cases xs with
  | nil => simp
  | cons a tail =>
    cases tail with
    | nil => simp
    | cons b rest => simp at h

/-- The two failing witnesses are confined to the unbounded descriptor; no
    static or bounded-dynamic descriptor has a failing admitted stream. -/
theorem classification : Classification := by
  intro d
  constructor
  · constructor
    · intro works bad
      subst d
      apply singleCounterexample
      intro desc xs adm guard
      by_cases h : desc = .unbounded
      · subst desc; exact works xs adm guard
      · exact trivialList desc h xs adm guard _
    · intro finite xs adm guard
      exact trivialList d finite xs adm guard _
  · constructor
    · intro works bad
      subst d
      apply tupleCounterexample
      intro desc xs adm guard
      by_cases h : desc = .unbounded
      · subst desc; exact works xs adm guard
      · rw [trivialList desc h xs adm guard]
        exact ⟨rfl, rfl⟩
    · intro finite xs adm guard
      rw [trivialList d finite xs adm guard]
      exact ⟨rfl, rfl⟩
#print axioms classification
end RevisedBenchmark.DynamicSort
