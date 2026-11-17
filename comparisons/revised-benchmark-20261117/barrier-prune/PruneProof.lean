module
public import PruneSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.BarrierPrune
universe u

/-- Each retained prefix value contributes one position to the source index map. -/
private theorem prefixLength {α : Type u} (mask : Nat → Bool) (pre : List α) :
    (compact mask pre).length = newPosition mask pre.length := by
  have h := congrArg (fun l => (l.filter mask).length) (List.zipIdx_map_snd 0 pre)
  simp only [List.filter_map, List.length_map, List.range'_eq_map_range,
    Nat.zero_add, Function.comp_def] at h
  exact (List.length_map (f := Prod.fst)).trans h

/-- Keeping the selected element puts it immediately after the compacted prefix. -/
private theorem splitAt {α : Type u} (mask : Nat → Bool) (pre : List α) (x : α)
    (tail : List α) (kept : mask pre.length = true) :
    (compact mask (pre ++ x :: tail))[(compact mask pre).length]? = some x := by
  simp only [compact, List.zipIdx_append, Nat.zero_add, List.zipIdx_cons,
    List.filter_append, List.filter_cons, kept, List.map_append, List.map_cons, ite_true]
  rw [List.getElem?_append_right (by simp)]
  simp

/-- Split at the observed position and count the retained prefix. -/
theorem preserved : Goal.{u} := by
  intro α xs tupleOperand users token protectedProducer i hi
  let mask := keep tupleOperand users token protectedProducer
  have kept : mask i.val = true := by simp [mask, keep, hi]
  let pre := xs.take i.val
  have len : pre.length = i.val := by simp [pre, Nat.min_eq_left (Nat.le_of_lt i.isLt)]
  have split := (List.take_append_drop i.val xs).symm
  rw [List.drop_eq_getElem_cons i.isLt] at split
  have h := splitAt mask pre xs[i.val] (xs.drop (i.val+1)) (len ▸ kept)
  rw [prefixLength, len] at h
  exact (congrArg (fun l => (compact mask l)[newPosition mask i.val]?) split).trans h

private def flags (tupleOperand : Bool) :=
  keep tupleOperand [3, 3] (fun i => i == 1) (fun i => i == 2)
private def values := [11, 22, 33, 44, 55]

example : compact (flags true) values = [22, 33, 44] := by decide
example : compact (flags false) values = [22, 44] := by decide
example : newPosition (flags true) 3 = 2 ∧ newPosition (flags false) 3 = 1 := by decide
example : (compact (flags true) values)[3]? ≠ values[3]? := by decide
example : compact (keep true [] (fun _ => false) (fun _ => false)) values = [] := by decide

#print axioms preserved
end RevisedBenchmark.BarrierPrune
