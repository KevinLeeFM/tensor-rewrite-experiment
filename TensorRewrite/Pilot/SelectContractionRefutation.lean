module

public import TensorRewrite.Pilot.SelectContractionLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SelectContraction

/-- Every nonzero exact contraction changes for either uniform predicate. -/
theorem nonzero_sum_refutes (predicate : Bool) (xs : List Int) (h : sum xs ≠ 0) :
    branchContraction predicate xs ≠ hoistedContraction predicate xs := by
  rw [branchContraction_eq, hoistedContraction_eq]
  cases predicate
  · change 3 * sum xs ≠ 6 * sum xs
    omega
  · change 2 * sum xs ≠ 6 * sum xs
    omega

/-- The true branch of the native replay has the exact values eight and twenty-four. -/
theorem true_witness :
    branchContraction true [1, 1, 1, 1] = 8 ∧
      hoistedContraction true [1, 1, 1, 1] = 24 := by
  decide

/-- The false branch of the native replay has the exact values twelve and twenty-four. -/
theorem false_witness :
    branchContraction false [1, 1, 1, 1] = 12 ∧
      hoistedContraction false [1, 1, 1, 1] = 24 := by
  decide

/-- Combining the scalars of alternative Select branches is not a universal identity. -/
theorem not_universally_valid :
    ¬ (∀ predicate xs, branchContraction predicate xs = hoistedContraction predicate xs) := by
  intro preserving
  have h := true_witness.1.symm.trans ((preserving true [1, 1, 1, 1]).trans true_witness.2)
  exact (by decide : (8 : Int) ≠ 24) h

end TensorRewrite.Pilot.SelectContraction
