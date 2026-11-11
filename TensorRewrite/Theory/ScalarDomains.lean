module

public import TensorRewrite.Theory.ScalarDomainLemmas

/-! Real and principal-complex domains for retained logarithm and square-root targets.
These are exact mathematical values; rounded operations and fast-math policies are separate. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScalarDomains

/-- Real logarithm cancels real exponential on every real input. -/
theorem real_log_exp (x : ℝ) : Real.log (Real.exp x) = x := Real.log_exp x

/-- Real principal square root of a square gives absolute value, including negative inputs. -/
theorem real_sqrt_square (x : ℝ) : Real.sqrt (x * x) = |x| :=
  Real.sqrt_mul_self_eq_abs x

/-- On the conventional positive logarithm domain, log of a square root scales by one half. -/
theorem real_log_sqrt_pos (x : ℝ) (positive : 0 < x) :
    Real.log (Real.sqrt x) = (1 / 2 : ℝ) * Real.log x := by
  simpa only [div_eq_mul_inv, one_mul, mul_comm] using Real.log_sqrt positive.le

/-- Principal complex log cancels exp exactly on its full principal imaginary strip. -/
theorem complex_log_exp_iff (z : ℂ) :
    Complex.log (Complex.exp z) = z ↔ -Real.pi < z.im ∧ z.im ≤ Real.pi := by
  constructor
  · intro equal
    have lower := Complex.neg_pi_lt_arg (Complex.exp z)
    have upper := Complex.arg_le_pi (Complex.exp z)
    rw [← Complex.log_im, equal] at lower upper
    exact ⟨lower, upper⟩
  · rintro ⟨lower, upper⟩
    exact Complex.log_exp lower upper

/-- Principal complex sqrt of a square equals the embedded magnitude exactly on the real axis. -/
theorem complex_sqrt_square_iff_real (z : ℂ) :
    Complex.sqrt (z * z) = (‖z‖ : ℂ) ↔ z.im = 0 := by
  constructor
  · intro equal
    have square : (‖z‖ : ℂ) ^ 2 = z * z := by
      rw [← equal]
      exact complex_square_sqrt _
    have realPart : ‖z‖ * ‖z‖ = z.re * z.re - z.im * z.im := by
      simpa only [pow_two, Complex.mul_re, Complex.ofReal_re, Complex.ofReal_im,
        mul_zero, sub_zero] using congrArg Complex.re square
    have magnitude := Complex.norm_mul_self_eq_normSq z
    rw [Complex.normSq_apply] at magnitude
    have imaginarySquare : z.im ^ 2 = 0 := by nlinarith
    exact sq_eq_zero_iff.mp imaginarySquare
  · intro realAxis
    have asReal : z = (z.re : ℂ) := by
      apply Complex.ext <;> simp [realAxis]
    rw [asReal]
    simpa only [Complex.norm_real, Real.norm_eq_abs] using complex_sqrt_square_ofReal z.re

/-- Real log/exp cancellation lifts to all tensor ranks and extents. -/
theorem real_log_exp_tensor {rank : Nat} {shape : Pilot.Shape rank}
    (input : Pilot.Tensor shape ℝ) :
    Pilot.Tensor.map Real.log (Pilot.Tensor.map Real.exp input) = input := by
  funext index
  exact real_log_exp (input index)

/-- The complete pointwise principal-strip condition characterizes tensor log/exp equality. -/
theorem complex_log_exp_tensor_iff {rank : Nat} {shape : Pilot.Shape rank}
    (input : Pilot.Tensor shape ℂ) :
    Pilot.Tensor.map Complex.log (Pilot.Tensor.map Complex.exp input) = input ↔
      ∀ index, -Real.pi < (input index).im ∧ (input index).im ≤ Real.pi := by
  constructor
  · intro equal index
    exact (complex_log_exp_iff (input index)).mp (congrFun equal index)
  · intro strip
    funext index
    exact (complex_log_exp_iff (input index)).mpr (strip index)

/-- Complex sqrt-square/magnitude equality holds on a tensor exactly when each value is real. -/
theorem complex_sqrt_square_tensor_iff {rank : Nat} {shape : Pilot.Shape rank}
    (input : Pilot.Tensor shape ℂ) :
    Pilot.Tensor.map (fun z => Complex.sqrt (z * z)) input =
        Pilot.Tensor.map (fun z => (‖z‖ : ℂ)) input ↔
      ∀ index, (input index).im = 0 := by
  constructor
  · intro equal index
    exact (complex_sqrt_square_iff_real (input index)).mp (congrFun equal index)
  · intro realAxis
    funext index
    exact (complex_sqrt_square_iff_real (input index)).mpr (realAxis index)

/-- Real sqrt-square cancellation lifts to every tensor, including empty shapes. -/
theorem real_sqrt_square_tensor {rank : Nat} {shape : Pilot.Shape rank}
    (input : Pilot.Tensor shape ℝ) :
    Pilot.Tensor.map (fun x => Real.sqrt (x * x)) input =
      Pilot.Tensor.map (fun x => |x|) input := by
  funext index
  exact real_sqrt_square (input index)

/-- The conventional positive log/sqrt identity lifts under pointwise positive inputs. -/
theorem real_log_sqrt_tensor_pos {rank : Nat} {shape : Pilot.Shape rank}
    (input : Pilot.Tensor shape ℝ) (positive : ∀ index, 0 < input index) :
    Pilot.Tensor.map (fun x => Real.log (Real.sqrt x)) input =
      Pilot.Tensor.map (fun x => (1 / 2 : ℝ) * Real.log x) input := by
  funext index
  exact real_log_sqrt_pos (input index) (positive index)

end TensorRewrite.Theory.ScalarDomains
