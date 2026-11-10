module

public import Mathlib.Algebra.BigOperators.Group.Finset.Basic
public import Mathlib.Tactic.Ring

/-! Integration examples for the pinned mathematical proof baseline. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Libraries

/-- Exact integer factoring uses Mathlib's checked algebraic normalization. -/
theorem integer_factor (a b c : Int) : a * c + b * c = (a + b) * c := by
  ring

end TensorRewrite.Libraries
