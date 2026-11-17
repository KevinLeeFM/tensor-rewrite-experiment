module
public import OrderSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleProjection.Order
open TensorRewrite.Pilot.DependencyOrder

/-- The original data path A → tuple → projection → B is present in every schedule. -/
theorem mustOrder (s : List (Fin 6)) (legal : before.IsSchedule s) :
    s.idxOf 1 < s.idxOf 4 :=
  Nat.lt_trans (legal.2.2.2 2 1 (by decide))
    (Nat.lt_trans (legal.2.2.2 3 2 (by decide)) (legal.2.2.2 4 3 (by decide)))

/-- Both effects execute, but the forwarded graph admits B before A. -/
theorem noRefinement : ¬ Refines := by
  intro claim
  have post : after.IsSchedule [0, 2, 1, 3] := by unfold Graph.IsSchedule; decide
  obtain ⟨s, valid, sameOrder⟩ := claim [0, 2, 1, 3] post
  exact (by decide : ¬ ([0, 2, 1, 3] : List (Fin 4)).idxOf 1 <
      ([0, 2, 1, 3] : List (Fin 4)).idxOf 2) (sameOrder.mpr (mustOrder s valid))

example : before.IsSchedule [0, 1, 2, 3, 4, 5] := by unfold Graph.IsSchedule; decide
example : after.IsSchedule [0, 1, 2, 3] := by unfold Graph.IsSchedule; decide
example : ¬ before.IsSchedule [0, 2, 3, 4, 1, 5] := by unfold Graph.IsSchedule; decide
#print axioms noRefinement
end RevisedBenchmark.TupleProjection.Order
