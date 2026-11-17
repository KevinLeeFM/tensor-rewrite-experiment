module
public import OrderedSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastOrdered
open TensorRewrite.Pilot LinearIndex

/-- An ordered projection can only decrease the element count on an inhabited rectangle;
    at equal counts it preserves the complete logical position. -/
private theorem pack {n m : Nat} (s : Shape m) (t : Shape n) (f : Fin m → Fin n)
    (ordered : ∀ a b, a < b → f a < f b) (matched : ∀ a, s a = t (f a))
    (i : Index s) (j : Index t) (proj : ∀ a, (i a).val = (j (f a)).val) :
    elementCount s ≤ elementCount t ∧
    (elementCount s = elementCount t → (linearize s i).val = (linearize t j).val) := by
  induction n generalizing m with
  | zero =>
    cases m with
    | zero => exact ⟨Nat.le_refl _, fun _ => rfl⟩
    | succ m => exact Fin.elim0 (f 0)
  | succ n ih =>
    let u : Shape n := fun a => t a.succ
    let k : Index u := fun a => j a.succ
    have ht : 0 < t 0 := Nat.zero_lt_of_lt (j 0).isLt
    have hu : 0 < elementCount u := Nat.zero_lt_of_lt (linearize u k).isLt
    by_cases missing : ∀ a, (f a).val ≠ 0
    · let g : Fin m → Fin n := fun a => ⟨(f a).val - 1, by have := (f a).isLt; have := missing a; omega⟩
      have hg (a) : (g a).succ = f a := by
        apply Fin.ext
        have := missing a
        change (f a).val - 1 + 1 = (f a).val
        omega
      have ord (a b) (hab : a < b) : g a < g b := by
        have h := ordered a b hab
        rw [← hg a, ← hg b] at h
        exact Fin.succ_lt_succ_iff.mp h
      obtain ⟨le, eq⟩ := ih s u g ord (fun a => by simpa only [u, hg] using matched a)
        i k (fun a => (proj a).trans (congrArg (fun b => (j b).val) (hg a).symm))
      change elementCount s ≤ t 0 * elementCount u ∧ _
      have inc : elementCount u ≤ t 0 * elementCount u := by
        calc _ = 1 * elementCount u := (Nat.one_mul _).symm
             _ ≤ _ := Nat.mul_le_mul_right _ ht
      refine ⟨Nat.le_trans le inc, fun same => ?_⟩
      change elementCount s = t 0 * elementCount u at same
      have tailEq : elementCount s = elementCount u := by omega
      have unit : t 0 = 1 := by
        have mulEq : t 0 * elementCount u = 1 * elementCount u := by
          rw [Nat.one_mul]; omega
        exact Nat.eq_of_mul_eq_mul_right hu mulEq
      have z : (j 0).val = 0 := by have h := (j 0).isLt; omega
      change _ = (j 0).val * elementCount u + (linearize u k).val
      simpa only [z, Nat.zero_mul, Nat.zero_add] using eq tailEq
    · cases m with
      | zero => exact False.elim (missing (fun a => Fin.elim0 a))
      | succ m =>
        have fzero : f 0 = 0 := by
          apply Fin.ext
          apply Classical.byContradiction
          intro hn
          apply missing
          intro a
          refine Fin.cases hn (fun b => ?_) a
          have h := ordered 0 b.succ (by exact Nat.zero_lt_succ _)
          change (f 0).val < (f b.succ).val at h
          omega
        let g : Fin m → Fin n := fun a => ⟨(f a.succ).val - 1, by have := (f a.succ).isLt; have h := ordered 0 a.succ (by exact Nat.zero_lt_succ _); change (f 0).val < (f a.succ).val at h; omega⟩
        have hg (a) : (g a).succ = f a.succ := by
          apply Fin.ext
          have h := ordered 0 a.succ (by exact Nat.zero_lt_succ _)
          change (f 0).val < (f a.succ).val at h
          change (f a.succ).val - 1 + 1 = (f a.succ).val
          omega
        have ord (a b) (hab : a < b) : g a < g b := by
          have h := ordered a.succ b.succ (Fin.succ_lt_succ_iff.mpr hab)
          rw [← hg a, ← hg b] at h
          exact Fin.succ_lt_succ_iff.mp h
        let v : Shape m := fun a => s a.succ
        let l : Index v := fun a => i a.succ
        obtain ⟨le, eq⟩ := ih v u g ord (fun a => by simpa only [v, u, hg] using matched a.succ)
          l k (fun a => (proj a.succ).trans (congrArg (fun b => (j b).val) (hg a).symm))
        have head : s 0 = t 0 := by simpa only [fzero] using matched 0
        have hcoord : (i 0).val = (j 0).val := (proj 0).trans (congrArg (fun b => (j b).val) fzero)
        change s 0 * elementCount v ≤ t 0 * elementCount u ∧ _
        refine ⟨head ▸ Nat.mul_le_mul_left _ le, fun same => ?_⟩
        change s 0 * elementCount v = t 0 * elementCount u at same
        rw [head] at same
        have tailEq := Nat.eq_of_mul_eq_mul_left ht same
        change (i 0).val * elementCount v + (linearize v l).val =
          (j 0).val * elementCount u + (linearize u k).val
        have mulEq := congr (congrArg Nat.mul hcoord) tailEq
        exact congr (congrArg Nat.add mulEq) (eq tailEq)

/-- Strict matched projections and row-major reshape coincide at equal element counts. -/
theorem orderedReshape : Target := by
  intro m n s t axes sorted matched same α x
  funext j
  let i := IndexMaps.broadcastIndex axes matched j
  have h := (pack s t axes.decode sorted matched i j (fun _ => rfl)).2 same
  apply congrArg x
  change i = delinearize s _
  rw [← delinearize_linearize s i]
  apply congrArg (delinearize s)
  exact Fin.ext h

example : Target := orderedReshape
#print axioms orderedReshape
end RevisedBenchmark.BroadcastOrdered
