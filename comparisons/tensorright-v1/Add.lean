module

public import TensorRewrite.Theory.ArithmeticFamilyProof

/-! Paper-era Add rules, instantiated from the existing general arithmetic theorem.
Each constant operand is admitted as an arbitrary tensor, a stronger value domain. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Add

open Pilot Theory.ArithmeticFamily

/-- `add/rule01`: reassociation for arbitrary same-shape tensor values. -/
theorem reassociate {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· + ·) (Tensor.map₂ (· + ·) (inputs 0) (inputs 1)) (inputs 2) =
      Tensor.map₂ (· + ·) (inputs 0) (Tensor.map₂ (· + ·) (inputs 1) (inputs 2)) := by
  simpa [Rule.lhs, Rule.rhs, Expr.addOrder, Expr.eval, Operations.exact] using
    rewrite_sound (Rule.addAssoc false false) inputs predicates

/-- `add/rule02`: adding a zero tensor on the right. -/
theorem zero_right {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· + ·) (inputs 0) (Tensor.constant 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Operations.exact] using
    rewrite_sound Rule.addZeroRight inputs predicates

/-- `add/rule03`: adding a zero tensor on the left. -/
theorem zero_left {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· + ·) (Tensor.constant 0) (inputs 0) = inputs 0 := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Operations.exact] using
    rewrite_sound Rule.addZeroLeft inputs predicates

/-- `add/rule04`: exchanging two same-shape addition operands. -/
theorem commute {α : Type} [CommRing α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (predicates : Nat → Tensor shape Bool) :
    Tensor.map₂ (· + ·) (inputs 0) (inputs 1) =
      Tensor.map₂ (· + ·) (inputs 1) (inputs 0) := by
  simpa [Rule.lhs, Rule.rhs, Expr.eval, Operations.exact] using
    rewrite_sound Rule.addComm inputs predicates

#print axioms reassociate
#print axioms zero_right
#print axioms zero_left
#print axioms commute

end TensorRewrite.PaperComparison.Add
