import TensorRewrite.Theory.ScalarDomainCounterexamples

set_option autoImplicit false

namespace ScalarDomainControls

open TensorRewrite.Theory.ScalarDomains TensorRewrite.Pilot

/-- Direct evaluation of the two expressions in the imaginary-unit square-root witness. -/
theorem imaginary_square_root : Complex.sqrt (Complex.I * Complex.I) = Complex.I := by
  norm_num [Complex.sqrt_neg_one]

/-- Complex absolute value in this mathematical contract is the real magnitude. -/
theorem imaginary_magnitude : ‖Complex.I‖ = (1 : ℝ) := by norm_num

/-- A complete exponential period maps to one, whose principal logarithm is zero. -/
theorem full_period_log :
    Complex.log (Complex.exp (2 * (Real.pi : ℂ) * Complex.I)) = 0 := by
  rw [Complex.exp_two_pi_mul_I, Complex.log_one]

/-- The upper branch endpoint is included in the principal strip. -/
theorem upper_branch_endpoint :
    Complex.log (Complex.exp ((Real.pi : ℂ) * Complex.I)) = (Real.pi : ℂ) * Complex.I := by
  apply (complex_log_exp_iff _).mpr
  constructor
  · norm_num
    exact Real.pi_pos
  · norm_num

/-- The lower branch endpoint is excluded, so the two inequalities cannot both be closed. -/
theorem lower_branch_endpoint :
    Complex.log (Complex.exp (-(Real.pi : ℂ) * Complex.I)) ≠ -(Real.pi : ℂ) * Complex.I := by
  intro equal
  have lower := ((complex_log_exp_iff _).mp equal).1
  norm_num at lower

/-- A negative real square root of a square returns a positive magnitude. -/
theorem negative_real_square : Real.sqrt ((-2 : ℝ) * (-2)) = 2 := by
  apply (Real.sqrt_eq_iff_mul_self_eq (by norm_num) (by norm_num)).mpr
  norm_num

private def emptyShape : Shape 1 := fun _ => 0

/-- An empty tensor can satisfy equality vacuously even for a constant nonreal function. -/
theorem empty_nonreal_tensor :
    Tensor.map (fun z => Complex.sqrt (z * z))
        (Tensor.constant (shape := emptyShape) Complex.I) =
      Tensor.map (fun z => (‖z‖ : ℂ))
        (Tensor.constant (shape := emptyShape) Complex.I) := by
  funext index
  exact Fin.elim0 (index ⟨0, by decide⟩)

private def scalarShape : Shape 0 := Fin.elim0

/-- A rank-zero tensor has one observation, so the imaginary-unit mismatch is observable. -/
theorem scalar_nonreal_tensor :
    Tensor.map (fun z => Complex.sqrt (z * z))
        (Tensor.constant (shape := scalarShape) Complex.I) ≠
      Tensor.map (fun z => (‖z‖ : ℂ))
        (Tensor.constant (shape := scalarShape) Complex.I) := by
  intro equal
  exact complex_sqrt_square_counterexample (congrFun equal (fun axis => Fin.elim0 axis))

end ScalarDomainControls

#print axioms ScalarDomainControls.imaginary_square_root
#print axioms ScalarDomainControls.imaginary_magnitude
#print axioms ScalarDomainControls.full_period_log
#print axioms ScalarDomainControls.upper_branch_endpoint
#print axioms ScalarDomainControls.lower_branch_endpoint
#print axioms ScalarDomainControls.negative_real_square
#print axioms ScalarDomainControls.empty_nonreal_tensor
#print axioms ScalarDomainControls.scalar_nonreal_tensor
