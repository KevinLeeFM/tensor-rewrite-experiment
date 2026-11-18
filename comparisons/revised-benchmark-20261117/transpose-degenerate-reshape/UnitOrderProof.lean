import UnitOrderSpec
namespace RevisedBenchmark.UnitOrder

private theorem strip (size digit : Nat → Nat) (axes : List Nat) (start)
    (bounded : ∀ i ∈ axes, digit i < size i) :
    ordinal size digit axes start = ordinal size digit (visible size axes) start := by
  induction axes generalizing start with
  | nil => rfl
  | cons i tail ih =>
    have rest : ∀ j ∈ tail, digit j < size j := fun j hj => bounded j (List.mem_cons_of_mem _ hj)
    by_cases h : size i = 1
    · have small := bounded i List.mem_cons_self
      have zero : digit i = 0 := by omega
      simpa [ordinal, visible, h, zero] using ih start rest
    · simpa [ordinal, visible, h] using ih (start * size i + digit i) rest

theorem verified : Goal := by
  intro rank perm size digit permutes _ sorted bounds α data
  have inputBounds : ∀ i ∈ List.range rank, digit i < size i := fun i hi =>
    bounds i (permutes.mem_iff.mpr hi)
  have sortedInput : (List.range rank).Pairwise (· ≤ ·) :=
    List.pairwise_lt_range.imp (fun h => Nat.le_of_lt h)
  have same : visible size perm = visible size (List.range rank) :=
    List.Perm.eq_of_pairwise (fun _ _ _ _ => Nat.le_antisymm) sorted
      (sortedInput.filter _) (permutes.filter _)
  rw [strip size digit (List.range rank) 0 inputBounds, strip size digit perm 0 bounds, same]
#print axioms verified
end RevisedBenchmark.UnitOrder
