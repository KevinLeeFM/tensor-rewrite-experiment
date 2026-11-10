module

public import TensorRewrite.Pilot.OrderedCompareProfile

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.OrderedCompareProfile

/-- The false result always satisfies this necessary condition. -/
theorem false_consistent (lhs rhs : Bits) : IsOrderedCompatible lhs rhs false := fun _ => rfl

/-- A true ordered comparison contradicts a left NaN operand. -/
theorem true_incompatible_of_left_nan (lhs rhs : Bits) (nan : IsNaN lhs) :
    ¬ IsOrderedCompatible lhs rhs true := by
  intro valid
  exact Bool.noConfusion (valid (Or.inl nan))

/-- The same necessary condition applies to a right NaN operand. -/
theorem true_incompatible_of_right_nan (lhs rhs : Bits) (nan : IsNaN rhs) :
    ¬ IsOrderedCompatible lhs rhs true := by
  intro valid
  exact Bool.noConfusion (valid (Or.inr nan))

/-- The witness exponent and fraction identify a quiet NaN. -/
theorem quiet_nan_is_nan : IsNaN quietNaN := by decide

/-- The source's GE true-fold fails this profile on the left-NaN witness. -/
theorem quiet_nan_left_refutes : ¬ IsOrderedCompatible quietNaN zero true :=
  true_incompatible_of_left_nan quietNaN zero quiet_nan_is_nan

/-- The source's LE true-fold fails this profile on the right-NaN witness. -/
theorem quiet_nan_right_refutes : ¬ IsOrderedCompatible zero quietNaN true :=
  true_incompatible_of_right_nan zero quietNaN quiet_nan_is_nan

end TensorRewrite.Pilot.OrderedCompareProfile
