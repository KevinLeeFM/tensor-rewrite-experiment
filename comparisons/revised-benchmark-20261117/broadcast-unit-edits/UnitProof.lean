module
public import UnitSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastUnits
open TensorRewrite.Pilot TensorRewrite.PaperComparison.Iota LinearIndex
private theorem decode {n : Nat} (k : Fin n → Bool) (i : Fin (positions k).length) :
    (kept k).decode i = (positions k)[i] := by
  apply Fin.ext
  simp [IndexMaps.BroadcastAxes.decode, kept, Fin.getElem_fin]

private theorem sorted {n : Nat} (k : Fin n → Bool) (i j : Fin (positions k).length)
    (lt : i < j) : (kept k).decode i < (kept k).decode j := by
  rw [decode, decode]
  have all : (List.finRange n).Pairwise (· < ·) := by
    apply List.pairwise_iff_getElem.mpr
    intro a b ha hb hab
    simp only [List.getElem_finRange]
    exact hab
  exact List.pairwise_iff_getElem.mp (all.filter k) _ _ i.isLt j.isLt lt

/-- Directly eliminate the inserted-axis reshape using ordered projection and map composition. -/
theorem inserted : Inserted := by
  intro m n s t k b h count α x
  have projection := BroadcastOrdered.orderedReshape (keptShape s k) s (kept k) (sorted k)
    (fun _ => rfl) count α x
  rw [← projection]
  exact broadcast_composition (kept k) b (fun _ => rfl) h x

private theorem retainedProduct {m : Nat} (s : Shape m) (l : List (Fin m)) :
    ((l.filter (fun i => decide (s i ≠ 1))).map s).prod = (l.map s).prod := by
  induction l with
  | nil => rfl
  | cons a l ih =>
    simp only [List.filter_cons, decide_eq_true_eq]
    split <;> rename_i h
    · simp only [List.map_cons, List.prod_cons, ih]
    · have one : s a = 1 := by omega
      simp only [List.map_cons, List.prod_cons, one, Nat.one_mul, ih]

private theorem countDrop {m : Nat} (s : Shape m) :
    elementCount s = elementCount (keptShape s (fun i => decide (s i ≠ 1))) := by
  rw [Heldout.ElementCount.count_as_list, Heldout.ElementCount.count_as_list]
  let keep := fun i => decide (s i ≠ 1)
  have eq : (List.finRange (positions keep).length).map (keptShape s keep) =
      (positions keep).map s := by
    have axisList : (List.finRange (positions keep).length).map (fun i => (kept keep).decode i) =
        positions keep := by
      apply List.ext_getElem
      · simp
      · intro i hi hj
        simp [decode, List.getElem_finRange]
    unfold keptShape
    simpa only [List.map_map, Function.comp_def] using congrArg (List.map s) axisList
  rw [eq]
  exact (retainedProduct s _).symm

/-- Removing every unit input axis preserves the original tensor-valued broadcast. -/
theorem dropped : Dropped := by
  intro m n s t b h α x
  let k := fun i => decide (s i ≠ 1)
  have eq : elementCount s = elementCount (keptShape s k) := countDrop s
  refine ⟨eq, ?_⟩
  let y := Reshape.reshapeTensor x (keptShape s k) eq
  have cancel : Reshape.reshapeTensor y s eq.symm = x := by
    funext i
    apply congrArg x
    rw [Reshape.reshapeIndex_compose]
    exact delinearize_linearize s i
  exact (congrArg (Tensor.reindex (IndexMaps.broadcastIndex b h)) cancel.symm).trans
    (inserted s t k b h eq.symm α y)

example : Inserted := inserted
example : Dropped := dropped
#print axioms inserted
#print axioms dropped
end RevisedBenchmark.BroadcastUnits
