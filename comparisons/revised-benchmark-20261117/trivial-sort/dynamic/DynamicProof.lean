module
public import DynamicSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicSort

private def keys := [1, 0]
private def rows : List (Nat × Bool) := [(1, true), (0, false)]
private theorem fires : forward .unbounded := Or.inr (by decide)
theorem singleCounterexample : ¬ SingleClaim := by
  intro claim
  have impossible := claim .unbounded keys trivial fires
  exact (by simp [keys, List.mergeSort_pair] : keys.mergeSort (fun a b => decide (a < b)) ≠ keys) impossible

theorem tupleCounterexample : ¬ TupleClaim := by
  intro claim
  have impossible := (claim .unbounded rows trivial fires).2
  exact (by simp [rows, List.mergeSort_pair] : (rows.mergeSort (fun a b => decide (a.1 < b.1))).map Prod.snd ≠
    rows.map Prod.snd) impossible

example : keys.mergeSort (fun a b => decide (a < b)) = [0, 1] := by simp [keys, List.mergeSort_pair]
example : rows.mergeSort (fun a b => decide (a.1 < b.1)) = [(0, false), (1, true)] := by simp [rows, List.mergeSort_pair]
example : ¬ forward (.fixed 2) ∧ ¬ forward (.bounded 2) := by
  simp [forward, Dim.stored]
example : ¬ (Dim.bounded 1).admits keys.length := by simp [keys, Dim.admits]
end RevisedBenchmark.DynamicSort
#print axioms RevisedBenchmark.DynamicSort.singleCounterexample
#print axioms RevisedBenchmark.DynamicSort.tupleCounterexample
