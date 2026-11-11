module

public import Mathlib.Analysis.RCLike.Sqrt
public import Mathlib.Analysis.SpecialFunctions.Complex.Log
public import Mathlib.Tactic.Linarith
public import Mathlib.Tactic.NormNum
public import TensorRewrite.Pilot.Tensor

/-! Principal complex square-root facts used to identify exact rewrite domains. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScalarDomains

open scoped ComplexOrder

/-- Squaring the principal complex square root recovers its argument. -/
theorem complex_square_sqrt (z : ℂ) : Complex.sqrt z ^ 2 = z := by
  exact Complex.cpow_nat_inv_pow z (n := 2) (by decide)

/-- On the real axis, the principal square root of a square is the embedded absolute value. -/
theorem complex_sqrt_square_ofReal (x : ℝ) :
    Complex.sqrt ((x : ℂ) * (x : ℂ)) = ((|x| : ℝ) : ℂ) := by
  rw [← Complex.ofReal_mul]
  have nonnegative : (0 : ℂ) ≤ ((x * x : ℝ) : ℂ) := by
    simpa only [Complex.zero_le_real] using mul_self_nonneg x
  rw [Complex.sqrt_of_nonneg nonnegative]
  simp [Real.sqrt_mul_self_eq_abs]

end TensorRewrite.Theory.ScalarDomains
