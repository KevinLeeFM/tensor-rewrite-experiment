module

public import TensorRewrite.Theory.ArithmeticFamilyProof

/-! Paper-era exact arithmetic rules, derived from the existing tensor theory. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.ScalarArithmetic

open Pilot Theory.ArithmeticFamily

/-- `sub/rule00`: preserves elementwise mathematical tensor values. -/
theorem sub_zero {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· - ·) (inputs 0) (Tensor.constant 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.subZero inputs predicates

/-- `sub/rule01`: preserves elementwise mathematical tensor values. -/
theorem sub_neg {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· - ·) (inputs 0) (inputs 1) =
      Tensor.map₂ (· + ·) (inputs 0) (Tensor.map (- ·) (inputs 1)) := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.subNeg inputs predicates

/-- `sub/rule02`: preserves elementwise mathematical tensor values. -/
theorem sub_self {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· - ·) (inputs 0) (inputs 0) = Tensor.constant 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.subSelf inputs predicates

/-- `mul/rule01`: preserves elementwise mathematical tensor values. -/
theorem mul_one_right {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (inputs 0) (Tensor.constant 1) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.mulOneRight inputs predicates

/-- `mul/rule02`: preserves elementwise mathematical tensor values. -/
theorem mul_one_left {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (Tensor.constant 1) (inputs 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.mulOneLeft inputs predicates

/-- `mul/rule03`: preserves elementwise mathematical tensor values. -/
theorem mul_zero_right {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (inputs 0) (Tensor.constant 0) = Tensor.constant 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.mulZeroRight inputs predicates

/-- `mul/rule04`: preserves elementwise mathematical tensor values. -/
theorem mul_zero_left {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (Tensor.constant 0) (inputs 0) = Tensor.constant 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound Rule.mulZeroLeft inputs predicates

/-- `mul/rule05`: preserves elementwise mathematical tensor values. -/
theorem mul_four_factors {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (Tensor.map₂ (· * ·) (inputs 0) (inputs 2))
        (Tensor.map₂ (· * ·) (inputs 1) (inputs 3)) =
      Tensor.map₂ (· * ·) (Tensor.map₂ (· * ·) (inputs 0) (inputs 1))
        (Tensor.map₂ (· * ·) (inputs 2) (inputs 3)) := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound (Rule.fourFactors false false false) inputs predicates

/-- `mul/rule06`: preserves elementwise mathematical tensor values. -/
theorem mul_reassociate {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· * ·) (Tensor.map₂ (· * ·) (inputs 0) (inputs 1)) (inputs 2) =
      Tensor.map₂ (· * ·) (inputs 0) (Tensor.map₂ (· * ·) (inputs 1) (inputs 2)) := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound (Rule.mulAssoc false false) inputs predicates

/-- `mul/rule08`: preserves elementwise mathematical tensor values. -/
theorem mul_factor {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· + ·) (Tensor.map₂ (· * ·) (inputs 0) (inputs 2))
        (Tensor.map₂ (· * ·) (inputs 1) (inputs 2)) =
      Tensor.map₂ (· * ·) (Tensor.map₂ (· + ·) (inputs 0) (inputs 1)) (inputs 2) := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.mulOrder, Expr.eval, Operations.exact] using
    rewrite_sound (Rule.factor false false) inputs predicates

#print axioms sub_zero
#print axioms sub_neg
#print axioms sub_self
#print axioms mul_one_right
#print axioms mul_one_left
#print axioms mul_zero_right
#print axioms mul_zero_left
#print axioms mul_four_factors
#print axioms mul_reassociate
#print axioms mul_factor

end TensorRewrite.PaperComparison.ScalarArithmetic
