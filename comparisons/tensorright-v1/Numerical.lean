module

public import TensorRewrite.Theory.NumericalReal

/-! Paper-era exact arithmetic identities; machine floating point is a separate model. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Numerical

open Pilot Theory.Numerical

/-- `divmod/rule00`: both paper numeric types divide by one without changing the input. -/
theorem divide_one_both {rank : Nat} {shape : Shape rank}
    (integerInput : Tensor shape Int) (realInput : Tensor shape ℝ) :
    Tensor.map₂ (· / ·) integerInput (Tensor.constant 1) = integerInput ∧
      Tensor.map₂ (· / ·) realInput (Tensor.constant 1) = realInput := by
  constructor
  · funext index
    simp [Tensor.map₂, Tensor.constant]
  · change (fun index => realInput index / 1) = realInput
    exact divide_one realInput

/-- `divmod/rule01`: exact real division by a scalar is multiplication by its reciprocal. -/
theorem divide_constant_real {rank : Nat} {shape : Shape rank}
    (input : Tensor shape ℝ) (value : ℝ) :
    Tensor.map₂ (· / ·) input (Tensor.constant value) =
      Tensor.map₂ (· * ·) input (Tensor.constant (1 / value)) := divide_constant input value

/-- `divmod/rule02`: division of quotients is cross multiplication in totalized real division. -/
theorem divide_fractions_real {rank : Nat} {shape : Shape rank}
    (a b c d : Tensor shape ℝ) :
    Tensor.map₂ (· / ·) (Tensor.map₂ (· / ·) a b) (Tensor.map₂ (· / ·) c d) =
      Tensor.map₂ (· / ·) (Tensor.map₂ (· * ·) a d) (Tensor.map₂ (· * ·) b c) := by
  change (fun index => (a index / b index) / (c index / d index)) =
    (fun index => (a index * d index) / (b index * c index))
  exact divide_fractions a b c d

/-- `divmod/rule03`: moving a nested divisor is valid for totalized exact real division. -/
theorem divide_nested_real {rank : Nat} {shape : Shape rank}
    (a b c : Tensor shape ℝ) :
    Tensor.map₂ (· / ·) a (Tensor.map₂ (· / ·) b c) =
      Tensor.map₂ (· / ·) (Tensor.map₂ (· * ·) a c) b := by
  change (fun index => a index / (b index / c index)) =
    (fun index => (a index * c index) / b index)
  exact divide_nested_denominator a b c

/-- `mul/rule09`: the absolute value does not change a square in either paper numeric type. -/
theorem abs_square {α : Type} [Ring α] [LinearOrder α] {rank : Nat} {shape : Shape rank}
    (input : Tensor shape α) :
    Tensor.map₂ (· * ·) (Tensor.map abs input) (Tensor.map abs input) =
      Tensor.map₂ (· * ·) input input := by
  funext index
  simp only [Tensor.map₂, Tensor.map, ← pow_two, sq_abs]

/-- `mul/rule10`: multiplication of exact real exponentials combines the exponents. -/
theorem exp_product_real {rank : Nat} {shape : Shape rank} (a b : Tensor shape ℝ) :
    Tensor.map₂ (· * ·) (Tensor.map Real.exp a) (Tensor.map Real.exp b) =
      Tensor.map Real.exp (Tensor.map₂ (· + ·) a b) := by
  change (fun index => Real.exp (a index) * Real.exp (b index)) =
    (fun index => Real.exp (a index + b index))
  exact real_exp_product a b

#print axioms divide_one_both
#print axioms divide_constant_real
#print axioms divide_fractions_real
#print axioms divide_nested_real
#print axioms abs_square
#print axioms exp_product_real

end TensorRewrite.PaperComparison.Numerical
