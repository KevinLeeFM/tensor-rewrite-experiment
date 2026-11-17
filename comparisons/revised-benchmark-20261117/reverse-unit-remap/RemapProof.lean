module
public import RemapSpec
public import Proof
public section
set_option autoImplicit false
namespace RevisedBenchmark.ReverseRemap
open TensorRewrite.Pilot BroadcastUnits TensorRewrite.Heldout.UnitReverse
private theorem ascending (n : Nat) : (List.finRange n).Pairwise (· < ·) := by
  apply List.pairwise_iff_getElem.mpr
  intro a b ha hb hab
  simp only [List.getElem_finRange]
  exact hab

private theorem countBefore {n : Nat} (l : List (Fin n)) (sorted : l.Pairwise (· < ·))
    (i : Nat) (hi : i < l.length) :
    (l.filter (fun j => decide (j < l[i]))).length = i := by
  induction l generalizing i with
  | nil => simp at hi
  | cons a l ih =>
    obtain ⟨head, tail⟩ := List.pairwise_cons.mp sorted
    cases i with
    | zero =>
      have hn : ¬ a < a := by omega
      simp only [List.getElem_cons_zero, List.filter_cons, decide_eq_true_eq, hn, ↓reduceIte]
      rw [List.filter_eq_nil_iff.mpr (fun j hj => by
        have := head j hj
        simp only [decide_eq_true_eq]
        omega)]
      rfl
    | succ i =>
      simp only [List.getElem_cons_succ]
      have ihb : i < l.length := by simpa using hi
      have h := head l[i] (List.getElem_mem (by simpa using hi))
      simp [h, ih tail i ihb]

private theorem partition {n : Nat} (l : List (Fin n)) (k : Fin n → Bool) (d : Fin n) :
    (((l.filter k).filter (fun j => decide (j < d))).length +
      ((l.filter (fun j => !k j)).filter (fun j => decide (j < d))).length) =
      (l.filter (fun j => decide (j < d))).length := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    cases hk : k a <;> by_cases less : a < d <;>
      simp [hk, less] at * <;> omega

/-- Rank/select of the actual ordered complement. -/
theorem ordinal_correct : OrdinalGoal := by
  intro n k i
  let d := (positions k)[i]
  have total := countBefore (List.finRange n) (ascending n) d.val (by simp)
  have atD : (List.finRange n)[d.val]'(by simp) = d := by simp [List.getElem_finRange]
  rw [atD] at total
  have sel := countBefore (positions k) ((ascending n).filter k) i.val i.isLt
  have sum := partition (List.finRange n) k d
  change _ + ((positions (fun j => !k j)).filter (fun j => decide (j < d))).length = _ at sum
  rw [total] at sum
  change ((positions k).filter (fun j => decide (j < d))).length = i.val at sel
  change ((positions k).filter (fun j => decide (j < d))).length + _ = d.val at sum
  rw [sel] at sum
  change d.val - ((positions (fun j => !k j)).filter (fun j => decide (j < d))).length = i.val
  omega

private theorem decoded {n : Nat} (k : Fin n → Bool) (i : Fin (positions k).length) :
    (kept k).decode i = (positions k)[i] := by
  apply Fin.ext
  simp [IndexMaps.BroadcastAxes.decode, kept, Fin.getElem_fin]

private theorem locate {n : Nat} (k : Fin n → Bool) (d : Fin n) (hk : k d = true) :
    ∃ i : Fin (positions k).length, (kept k).decode i = d := by
  have mem : d ∈ positions k := List.mem_filter.mpr ⟨List.mem_finRange _, hk⟩
  obtain ⟨i, hi, eq⟩ := List.mem_iff_getElem.mp mem
  exact ⟨⟨i, hi⟩, (decoded k _).trans eq⟩

private theorem mapped {n : Nat} (k : Fin n → Bool) (i : Fin (positions k).length) :
    ordinal k ((kept k).decode i) = i.val := (decoded k i) ▸ ordinal_correct k i

/-- Source loop emits valid distinct axes and commutes with row-major reshape. -/
theorem reverse_remap : Target := by
  intro n t k units eq dims α x
  let survivors := dims.filter (fun j => decide (t j ≠ 1))
  have keptSurvivor (d : Fin n) (hd : d ∈ survivors) : k d = true := by
    have nonunit := of_decide_eq_true (List.mem_filter.mp hd).2
    cases h : k d
    · exact False.elim (nonunit (units d h))
    · rfl
  have sorted (a b : Fin (positions k).length) (lt : a < b) :
      (kept k).decode a < (kept k).decode b := by
    rw [decoded, decoded]
    exact List.pairwise_iff_getElem.mp ((ascending n).filter k) _ _ a.isLt b.isLt lt
  let p : UnitInsertion (keptShape t k) t := {
    keptAxis := (kept k).decode
    increasing := sorted
    extent := fun _ => rfl
    insertedUnit := fun j missing => by
      apply units
      cases h : k j
      · rfl
      · obtain ⟨i, he⟩ := locate k j h
        exact False.elim (missing i he) }
  have rowMajor (y : Tensor (keptShape t k) α) :
      reshape p y = Reshape.reshapeTensor y t eq :=
    BroadcastOrdered.orderedReshape _ _ (kept k) sorted (fun _ => rfl) eq α y
  constructor
  · intro d hd
    obtain ⟨j, hj, rfl⟩ := List.mem_map.mp hd
    obtain ⟨i, rfl⟩ := locate k j (keptSurvivor j hj)
    rw [mapped]
    exact i.isLt
  constructor
  · intro distinct
    apply List.pairwise_map.mpr
    apply List.Pairwise.imp_of_mem (p := distinct.filter (fun j => decide (t j ≠ 1)))
    intro a b ha hb different same
    obtain ⟨i, rfl⟩ := locate k a (keptSurvivor a ha)
    obtain ⟨j, rfl⟩ := locate k b (keptSurvivor b hb)
    rw [mapped, mapped] at same
    exact different (congrArg (kept k).decode (Fin.ext same))
  · have masks : remappedAxes p (Tensor.axisMask dims) =
        fun i => decide (i.val ∈ emitted t k dims) := by
      funext i
      apply Bool.eq_iff_iff.mpr
      simp only [remappedAxes, Tensor.axisMask, decide_eq_true_eq, emitted, List.mem_map,
        List.mem_filter, decide_eq_true_eq]
      change (if t ((kept k).decode i) = 1 then false else decide ((kept k).decode i ∈ dims)) = true ↔ _
      constructor
      · intro h
        split at h
        · contradiction
        · rename_i nonunit
          exact ⟨_, ⟨of_decide_eq_true h, nonunit⟩, mapped k i⟩
      · rintro ⟨a, ⟨ha, hn⟩, he⟩
        have hk : k a = true := keptSurvivor a (List.mem_filter.mpr ⟨ha, decide_eq_true hn⟩)
        obtain ⟨j, rfl⟩ := locate k a hk
        rw [mapped] at he
        have ji : j = i := Fin.ext he
        subst j
        simp [hn, ha]
    rw [← rowMajor, ← rowMajor, ← masks]
    exact reverse_reshape α _ _ _ _ p _ x

example : OrdinalGoal := ordinal_correct
example : Target := reverse_remap
#print axioms ordinal_correct
#print axioms reverse_remap
end RevisedBenchmark.ReverseRemap
