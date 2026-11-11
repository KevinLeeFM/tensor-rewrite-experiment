module

public import TensorRewrite.Theory.ScalarDomains

/-! Exact principal-complex counterexample certificates; counted separately as C. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScalarDomains

/-- The unguarded complex log/exp identity fails at one complete imaginary period. -/
theorem complex_log_exp_counterexample :
    Complex.log (Complex.exp (2 * (Real.pi : ℂ) * Complex.I)) ≠
      2 * (Real.pi : ℂ) * Complex.I := by
  rw [Complex.exp_two_pi_mul_I, Complex.log_one]
  intro equal
  have imaginary := congrArg Complex.im equal
  norm_num at imaginary

/-- The unguarded complex sqrt-square/magnitude identity fails on the imaginary unit. -/
theorem complex_sqrt_square_counterexample :
    Complex.sqrt (Complex.I * Complex.I) ≠ (‖Complex.I‖ : ℂ) := by
  intro equal
  have realAxis := (complex_sqrt_square_iff_real Complex.I).mp equal
  norm_num at realAxis

end TensorRewrite.Theory.ScalarDomains
