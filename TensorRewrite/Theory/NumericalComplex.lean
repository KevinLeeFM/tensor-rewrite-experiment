module

public import TensorRewrite.Theory.NumericalReal
public import TensorRewrite.Theory.ScalarDomains

/-! Principal complex powers and square roots. Branch conditions are mathematical premises,
not assumptions about optimizer flags or rounded transcendental implementations. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Numerical

open Pilot

variable {rank : Nat} {shape : Shape rank}

/-- Real exponential of an arbitrary-shaped zero constant is a one constant. -/
theorem real_exp_zero :
    Tensor.map Real.exp (Tensor.constant (shape := shape) 0) = Tensor.constant 1 := by
  funext i
  exact Real.exp_zero

/-- Complex exponential of an arbitrary-shaped zero constant is a one constant. -/
theorem complex_exp_zero :
    Tensor.map Complex.exp (Tensor.constant (shape := shape) 0) = Tensor.constant 1 := by
  funext i
  exact Complex.exp_zero

/-- Complex exponential converts a product of exponentials to a sum without a branch premise. -/
theorem complex_exp_product (a b : Tensor shape ℂ) :
    (fun i => Complex.exp (a i) * Complex.exp (b i)) =
      (fun i => Complex.exp (a i + b i)) := by
  funext i
  exact (Complex.exp_add _ _).symm

/-- A quotient of complex exponentials is the exponential of their difference. -/
theorem complex_exp_quotient (a b : Tensor shape ℂ) :
    (fun i => Complex.exp (a i) / Complex.exp (b i)) =
      (fun i => Complex.exp (a i - b i)) := by
  funext i
  exact (Complex.exp_sub _ _).symm

/-- A complex exponential denominator can be negated before exponentiation. -/
theorem complex_exp_denominator (a b : Tensor shape ℂ) :
    (fun i => a i / Complex.exp (b i)) = (fun i => a i * Complex.exp (-b i)) := by
  funext i
  rw [Complex.exp_neg, div_eq_mul_inv]

/-- Complex negated powers invert principal powers, including the zero-base convention. -/
theorem complex_power_denominator (a b c : Tensor shape ℂ) :
    (fun i => a i / (b i ^ c i)) = (fun i => a i * (b i ^ (-c i))) := by
  funext i
  rw [Complex.cpow_neg, div_eq_mul_inv]

/-- Squaring the principal complex square root recovers the entire complex tensor. -/
theorem complex_sqrt_square (a : Tensor shape ℂ) :
    (fun i => Complex.sqrt (a i) * Complex.sqrt (a i)) = a := by
  funext i
  simpa only [pow_two] using ScalarDomains.complex_square_sqrt (a i)

/-- Squaring the reciprocal principal complex square root recovers the reciprocal. -/
theorem complex_rsqrt_square (a : Tensor shape ℂ) :
    (fun i => (Complex.sqrt (a i))⁻¹ * (Complex.sqrt (a i))⁻¹) =
      (fun i => 1 / a i) := by
  funext i
  rw [← mul_inv_rev, ← pow_two, ScalarDomains.complex_square_sqrt, one_div]

/-- Complex power zero produces a uniform one, including at base zero. -/
theorem complex_power_zero (a : Tensor shape ℂ) :
    (fun i => a i ^ (0 : ℂ)) = Tensor.constant 1 := by
  funext i
  exact Complex.cpow_zero _

/-- Complex power one preserves the input. -/
theorem complex_power_one (a : Tensor shape ℂ) : (fun i => a i ^ (1 : ℂ)) = a := by
  funext i
  exact Complex.cpow_one _

/-- Complex power two agrees with the duplicated product graph. -/
theorem complex_power_two (a : Tensor shape ℂ) :
    (fun i => a i ^ (2 : ℂ)) = (fun i => a i * a i) := by
  funext i
  rw [show (2 : ℂ) = (2 : Nat) by norm_num, Complex.cpow_natCast, pow_two]

/-- Complex power three agrees with the right-associated product graph. -/
theorem complex_power_three (a : Tensor shape ℂ) :
    (fun i => a i ^ (3 : ℂ)) = (fun i => a i * (a i * a i)) := by
  funext i
  rw [show (3 : ℂ) = (3 : Nat) by norm_num, Complex.cpow_natCast]
  ring

/-- Complex power minus one agrees with the totalized reciprocal. -/
theorem complex_power_minus_one (a : Tensor shape ℂ) :
    (fun i => a i ^ (-1 : ℂ)) = (fun i => 1 / a i) := by
  funext i
  rw [Complex.cpow_neg_one, one_div]

/-- Complex power one half is the principal square root. -/
theorem complex_power_half (a : Tensor shape ℂ) :
    (fun i => a i ^ (1 / 2 : ℂ)) = Tensor.map Complex.sqrt a := by
  funext i
  simp only [Complex.sqrt, one_div, Tensor.map]

/-- Power of complex exp agrees with exp of product on the principal strip of its input. -/
theorem complex_power_exp_strip (a b : Tensor shape ℂ)
    (strip : ∀ i, -Real.pi < (a i).im ∧ (a i).im ≤ Real.pi) :
    (fun i => Complex.exp (a i) ^ b i) = (fun i => Complex.exp (a i * b i)) := by
  funext i
  rw [Complex.cpow_def_of_ne_zero (Complex.exp_ne_zero _),
    Complex.log_exp (strip i).1 (strip i).2]

/-- At nonzero complex bases, log of power gives the selected product exactly on its strip. -/
theorem complex_log_power_iff (a b : Tensor shape ℂ) (nonzero : ∀ i, a i ≠ 0) :
    (fun i => Complex.log (a i ^ b i)) =
        (fun i => if b i = 0 then 0 else Complex.log (a i) * b i) ↔
      ∀ i, -Real.pi < (Complex.log (a i) * b i).im ∧
        (Complex.log (a i) * b i).im ≤ Real.pi := by
  have selected (i : Index shape) :
      (if b i = 0 then 0 else Complex.log (a i) * b i) = Complex.log (a i) * b i := by
    split_ifs with zero
    · simp [zero]
    · rfl
  simp_rw [selected, Complex.cpow_def_of_ne_zero (nonzero _)]
  constructor
  · intro equal i
    exact (ScalarDomains.complex_log_exp_iff _).mp (congrFun equal i)
  · intro strip
    funext i
    exact (ScalarDomains.complex_log_exp_iff _).mpr (strip i)

/-- Division by complex sqrt is multiplication by its explicitly defined reciprocal. -/
theorem complex_divide_sqrt (a b : Tensor shape ℂ) :
    (fun i => a i / Complex.sqrt (b i)) =
      (fun i => a i * (Complex.sqrt (b i))⁻¹) := by
  funext i
  exact div_eq_mul_inv _ _

/-- Division by reciprocal complex sqrt cancels the double inverse, including at zero. -/
theorem complex_divide_rsqrt (a b : Tensor shape ℂ) :
    (fun i => a i / (Complex.sqrt (b i))⁻¹) =
      (fun i => a i * Complex.sqrt (b i)) := by
  funext i
  simp only [div_eq_mul_inv, inv_inv]

end TensorRewrite.Theory.Numerical
