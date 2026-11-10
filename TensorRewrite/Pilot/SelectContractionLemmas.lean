module

public import TensorRewrite.Pilot.SelectContraction

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SelectContraction

/-- A uniform predicate chooses one scale for the entire exact contraction. -/
theorem branchContraction_eq (predicate : Bool) (xs : List Int) :
    branchContraction predicate xs = (if predicate then 2 else 3) * sum xs := by
  cases predicate <;> induction xs with
  | nil => rfl
  | cons x xs ih =>
    simp only [branchContraction, List.map_cons, sum, Bool.false_eq_true,
      ite_false, ite_true] at *
    rw [ih, Int.mul_add]

/-- The unscaled branches coincide, independently of the predicate. -/
theorem hoistedContraction_eq (predicate : Bool) (xs : List Int) :
    hoistedContraction predicate xs = 6 * sum xs := by
  simp [hoistedContraction]

end TensorRewrite.Pilot.SelectContraction
