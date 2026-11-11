module

public import TensorRewrite.Theory.NumericalComplex

/-! Exact witnesses rejecting missing sign and complex-branch premises. These do not model
rounded transcendental implementations or establish optimizer behavior. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Numerical

/-- Removing nonnegativity from real sqrt-square fails at minus one. -/
theorem real_sqrt_square_refuted : Real.sqrt (-1) * Real.sqrt (-1) ≠ (-1 : ℝ) := by
  norm_num [Real.sqrt_eq_zero_of_nonpos]

/-- Inverse-square rsqrt loses the sign of a negative real input. -/
theorem real_rsqrt_inverse_square_refuted :
    (Real.sqrt ((-1 : ℝ) ^ (-2 : ℝ)))⁻¹ ≠ (-1 : ℝ) := by
  rw [Real.rpow_neg_ofNat]
  norm_num

/-- With the actual real-power negative-base convention, negating an exponent need not invert. -/
theorem real_power_denominator_refuted :
    (1 : ℝ) / ((-1 : ℝ) ^ (1 / 3 : ℝ)) ≠
      (1 : ℝ) * ((-1 : ℝ) ^ (-(1 / 3) : ℝ)) := by
  have positive : (-1 : ℝ) ^ (1 / 3 : ℝ) = 1 / 2 := by
    rw [Real.rpow_def_of_neg (by norm_num)]
    norm_num [show (1 / 3 : ℝ) * Real.pi = Real.pi / 3 by ring,
      Real.cos_pi_div_three]
  have negative : (-1 : ℝ) ^ (-(1 / 3) : ℝ) = 1 / 2 := by
    rw [Real.rpow_def_of_neg (by norm_num)]
    norm_num [show (-(1 / 3) : ℝ) * Real.pi = -(Real.pi / 3) by ring,
      Real.cos_pi_div_three]
  rw [positive, negative]
  norm_num

/-- Principal complex sqrt does not commute with reciprocal on the negative real axis. -/
theorem complex_rsqrt_reciprocal_refuted :
    (Complex.sqrt (1 / (-1 : ℂ)))⁻¹ ≠ Complex.sqrt (-1 : ℂ) := by
  norm_num only [div_neg, div_one, Complex.sqrt_neg_one, Complex.inv_I]
  intro equal
  have imaginary := congrArg Complex.im equal
  norm_num at imaginary

/-- Power of a complex exponential is branch sensitive at a complete imaginary period. -/
theorem complex_power_exp_refuted :
    Complex.exp (2 * (Real.pi : ℂ) * Complex.I) ^ (1 / 2 : ℂ) ≠
      Complex.exp ((2 * (Real.pi : ℂ) * Complex.I) * (1 / 2 : ℂ)) := by
  rw [Complex.exp_two_pi_mul_I, Complex.one_cpow]
  rw [show (2 * (Real.pi : ℂ) * Complex.I) * (1 / 2 : ℂ) =
    (Real.pi : ℂ) * Complex.I by ring, Complex.exp_pi_mul_I]
  norm_num

end TensorRewrite.Theory.Numerical
