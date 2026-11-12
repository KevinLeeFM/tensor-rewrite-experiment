module

public import TensorRewrite.Theory.LogicalFamilyProof
public import TensorRewrite.Theory.ArithmeticFamilyProof

/-! Paper-era Boolean and double-negation rules on arbitrary finite shapes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Logical

open Pilot Theory.LogicalFamily

/-- `logical/rule01`: Boolean operation on every tensor coordinate. -/
theorem or_true_right {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.or (inputs 0) (Tensor.constant true) = Tensor.constant true := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.orTrueRight inputs trivial)

/-- `logical/rule02`: Boolean operation on every tensor coordinate. -/
theorem or_true_left {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.or (Tensor.constant true) (inputs 0) = Tensor.constant true := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.orTrueLeft inputs trivial)

/-- `logical/rule03`: Boolean operation on every tensor coordinate. -/
theorem or_false_right {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.or (inputs 0) (Tensor.constant false) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.orZeroRight inputs trivial)

/-- `logical/rule04`: Boolean operation on every tensor coordinate. -/
theorem or_false_left {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.or (Tensor.constant false) (inputs 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.orZeroLeft inputs trivial)

/-- `logical/rule05`: Boolean operation on every tensor coordinate. -/
theorem and_true_right {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.and (inputs 0) (Tensor.constant true) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.andTrueRight inputs trivial)

/-- `logical/rule06`: Boolean operation on every tensor coordinate. -/
theorem and_true_left {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.and (Tensor.constant true) (inputs 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.andTrueLeft inputs trivial)

/-- `logical/rule07`: Boolean operation on every tensor coordinate. -/
theorem and_false_right {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.and (inputs 0) (Tensor.constant false) = Tensor.constant false := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.andZeroRight inputs trivial)

/-- `logical/rule08`: Boolean operation on every tensor coordinate. -/
theorem and_false_left {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map₂ Bool.and (Tensor.constant false) (inputs 0) = Tensor.constant false := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.or, Domain.and, Domain.zero] using
    (rewrite_sound (domain := .predicate) Rule.andZeroLeft inputs trivial)

/-- `not/rule01`: Boolean double negation. -/
theorem not_not {rank : Nat} {shape : Shape rank} (inputs : Nat → Tensor shape Bool) :
    Tensor.map Bool.not (Tensor.map Bool.not (inputs 0)) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Domain.not] using
    (rewrite_sound (domain := .predicate) Rule.notNot inputs trivial)

/-- `not/rule02`: arithmetic double negation over exact integers and reals. -/
theorem neg_neg {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map (- ·) (Tensor.map (- ·) (inputs 0)) = inputs 0 := by
  simpa [Theory.ArithmeticFamily.Rule.lhs, Theory.ArithmeticFamily.Rule.rhs,
    Theory.ArithmeticFamily.Expr.eval, Theory.ArithmeticFamily.Operations.exact] using
    Theory.ArithmeticFamily.rewrite_sound Theory.ArithmeticFamily.Rule.negNeg inputs predicates

#print axioms or_true_right
#print axioms or_true_left
#print axioms or_false_right
#print axioms or_false_left
#print axioms and_true_right
#print axioms and_true_left
#print axioms and_false_right
#print axioms and_false_left
#print axioms not_not
#print axioms neg_neg

end TensorRewrite.PaperComparison.Logical
