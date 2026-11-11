module

public import TensorRewrite.Theory.NumericalField
public import Mathlib.Analysis.SpecialFunctions.Pow.Real

/-! Real numerical graph identities using actual Mathlib exp, rpow and nonnegative sqrt.
An inverse at zero is zero. Statements with a positive domain do not use log-zero totalization. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Numerical

open Pilot

variable {rank : Nat} {shape : Shape rank}

/-- The product of two real exponentials is the exponential of their sum. -/
theorem real_exp_product (a b : Tensor shape ℝ) :
    (fun i => Real.exp (a i) * Real.exp (b i)) = (fun i => Real.exp (a i + b i)) := by
  funext i
  exact (Real.exp_add _ _).symm

/-- A quotient of real exponentials is the exponential of their difference. -/
theorem real_exp_quotient (a b : Tensor shape ℝ) :
    (fun i => Real.exp (a i) / Real.exp (b i)) = (fun i => Real.exp (a i - b i)) := by
  funext i
  exact (Real.exp_sub _ _).symm

/-- An exponential denominator can be replaced by the exponential of the negated input. -/
theorem real_exp_denominator (a b : Tensor shape ℝ) :
    (fun i => a i / Real.exp (b i)) = (fun i => a i * Real.exp (-b i)) := by
  funext i
  rw [Real.exp_neg, div_eq_mul_inv]

/-- Real power denominators admit a negated exponent for pointwise nonnegative bases. -/
theorem real_power_denominator (a b c : Tensor shape ℝ) (nonnegative : ∀ i, 0 ≤ b i) :
    (fun i => a i / (b i ^ c i)) = (fun i => a i * (b i ^ (-c i))) := by
  funext i
  rw [Real.rpow_neg (nonnegative i), div_eq_mul_inv]

/-- Squaring an absolute value preserves the square for every real input. -/
theorem real_abs_square (a : Tensor shape ℝ) :
    (fun i => |a i| * |a i|) = (fun i => a i * a i) := by
  funext i
  simp only [← pow_two, sq_abs]

/-- Sqrt followed by a square recovers precisely the nonnegative real tensor domain. -/
theorem real_sqrt_square_iff (a : Tensor shape ℝ) :
    (fun i => Real.sqrt (a i) * Real.sqrt (a i)) = a ↔ ∀ i, 0 ≤ a i := by
  constructor
  · intro equal i
    rw [← congrFun equal i]
    exact mul_self_nonneg _
  · intro nonnegative
    funext i
    exact Real.mul_self_sqrt (nonnegative i)

/-- A squared reciprocal square root is a reciprocal precisely on nonnegative real inputs. -/
theorem real_rsqrt_square_iff (a : Tensor shape ℝ) :
    (fun i => (Real.sqrt (a i))⁻¹ * (Real.sqrt (a i))⁻¹) =
        (fun i => 1 / a i) ↔ ∀ i, 0 ≤ a i := by
  constructor
  · intro equal
    apply (real_sqrt_square_iff a).mp
    funext i
    apply inv_injective
    simpa only [mul_inv_rev, one_div] using congrFun equal i
  · intro nonnegative
    funext i
    rw [← mul_inv_rev, Real.mul_self_sqrt (nonnegative i), one_div]

/-- Real exponent zero gives a uniform one tensor, including at base zero. -/
theorem real_power_zero (a : Tensor shape ℝ) :
    (fun i => a i ^ (0 : ℝ)) = Tensor.constant 1 := by
  funext i
  exact Real.rpow_zero _

/-- Real exponent one preserves the base, including negative and zero bases. -/
theorem real_power_one (a : Tensor shape ℝ) : (fun i => a i ^ (1 : ℝ)) = a := by
  funext i
  exact Real.rpow_one _

/-- Real exponent two agrees with the explicitly duplicated product graph. -/
theorem real_power_two (a : Tensor shape ℝ) :
    (fun i => a i ^ (2 : ℝ)) = (fun i => a i * a i) := by
  funext i
  rw [Real.rpow_two, pow_two]

/-- Real exponent three agrees with the right-associated duplicated product graph. -/
theorem real_power_three (a : Tensor shape ℝ) :
    (fun i => a i ^ (3 : ℝ)) = (fun i => a i * (a i * a i)) := by
  funext i
  rw [show (3 : ℝ) = (3 : Nat) by norm_num, Real.rpow_natCast]
  ring

/-- Real exponent minus one is the totalized reciprocal. -/
theorem real_power_minus_one (a : Tensor shape ℝ) :
    (fun i => a i ^ (-1 : ℝ)) = (fun i => 1 / a i) := by
  funext i
  rw [Real.rpow_neg_one, one_div]

/-- Real exponent one half agrees with the nonnegative square root on all real bases. -/
theorem real_power_half (a : Tensor shape ℝ) :
    (fun i => a i ^ (1 / 2 : ℝ)) = Tensor.map Real.sqrt a := by
  funext i
  exact (Real.sqrt_eq_rpow _).symm

/-- Power of a real exponential has no branch restriction on either real tensor. -/
theorem real_power_exp (a b : Tensor shape ℝ) :
    (fun i => Real.exp (a i) ^ b i) = (fun i => Real.exp (a i * b i)) := by
  funext i
  exact (Real.exp_mul _ _).symm

/-- Log of real power gives the selected product on the conventional positive base domain. -/
theorem real_log_power_pos (a b : Tensor shape ℝ) (positive : ∀ i, 0 < a i) :
    (fun i => Real.log (a i ^ b i)) =
      (fun i => if b i = 0 then 0 else Real.log |a i| * b i) := by
  funext i
  rw [Real.log_rpow (positive i), abs_of_pos (positive i)]
  split_ifs with zero
  · rw [zero, zero_mul]
  · exact mul_comm _ _

/-- Log of reciprocal square root scales log by minus one half on positive real inputs. -/
theorem real_log_rsqrt_pos (a : Tensor shape ℝ) (positive : ∀ i, 0 < a i) :
    (fun i => Real.log (Real.sqrt (a i))⁻¹) =
      (fun i => Real.log (a i) * (-1 / 2 : ℝ)) := by
  funext i
  rw [Real.log_inv, Real.log_sqrt (positive i).le]
  ring

/-- Reciprocal square root of a real inverse square returns absolute value, including zero. -/
theorem real_rsqrt_inverse_square (a : Tensor shape ℝ) :
    (fun i => (Real.sqrt (a i ^ (-2 : ℝ)))⁻¹) = Tensor.map abs a := by
  funext i
  change (Real.sqrt (a i ^ (-2 : ℝ)))⁻¹ = |a i|
  rw [Real.rpow_neg_ofNat, zpow_neg, zpow_ofNat, Real.sqrt_inv,
    Real.sqrt_sq_eq_abs, inv_inv]

/-- The inverse-square rewrite returns the original real tensor exactly when it is nonnegative. -/
theorem real_rsqrt_inverse_square_iff (a : Tensor shape ℝ) :
    (fun i => (Real.sqrt (a i ^ (-2 : ℝ)))⁻¹) = a ↔ ∀ i, 0 ≤ a i := by
  rw [real_rsqrt_inverse_square]
  constructor
  · intro equal i
    exact abs_eq_self.mp (congrFun equal i)
  · intro nonnegative
    funext i
    exact abs_of_nonneg (nonnegative i)

/-- Reciprocal square root of a real reciprocal equals square root, even under totalization. -/
theorem real_rsqrt_reciprocal (a : Tensor shape ℝ) :
    (fun i => (Real.sqrt (1 / a i))⁻¹) = Tensor.map Real.sqrt a := by
  funext i
  simp [Tensor.map, Real.sqrt_inv]

/-- Division by real sqrt is multiplication by its explicitly defined reciprocal. -/
theorem real_divide_sqrt (a b : Tensor shape ℝ) :
    (fun i => a i / Real.sqrt (b i)) =
      (fun i => a i * (Real.sqrt (b i))⁻¹) := by
  funext i
  exact div_eq_mul_inv _ _

/-- Division by reciprocal real sqrt cancels the double inverse, including at zero. -/
theorem real_divide_rsqrt (a b : Tensor shape ℝ) :
    (fun i => a i / (Real.sqrt (b i))⁻¹) =
      (fun i => a i * Real.sqrt (b i)) := by
  funext i
  simp only [div_eq_mul_inv, inv_inv]

end TensorRewrite.Theory.Numerical
