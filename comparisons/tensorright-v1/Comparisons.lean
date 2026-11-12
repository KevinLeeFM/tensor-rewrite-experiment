module

public import TensorRewrite.Theory.OrderFamilyProof
public import TensorRewrite.Theory.OrderInstances

/-! Paper-era comparison rules over exact linearly ordered tensor values. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Comparisons

open Pilot Theory.OrderFamily

/-- `compare/rule01`: the same input compared with itself. -/
theorem self_gt {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (b < a)) (inputs 0) (inputs 0) = Tensor.constant false := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .gt) inputs trivial)

/-- `compare/rule02`: the same input compared with itself. -/
theorem self_lt {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (a < b)) (inputs 0) (inputs 0) = Tensor.constant false := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .lt) inputs trivial)

/-- `compare/rule03`: the same input compared with itself. -/
theorem self_ne {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (a ≠ b)) (inputs 0) (inputs 0) = Tensor.constant false := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .ne) inputs trivial)

/-- `compare/rule04`: the same input compared with itself. -/
theorem self_ge {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (b ≤ a)) (inputs 0) (inputs 0) = Tensor.constant true := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .ge) inputs trivial)

/-- `compare/rule05`: the same input compared with itself. -/
theorem self_le {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (a ≤ b)) (inputs 0) (inputs 0) = Tensor.constant true := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .le) inputs trivial)

/-- `compare/rule06`: the same input compared with itself. -/
theorem self_eq {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (a = b)) (inputs 0) (inputs 0) = Tensor.constant true := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.compareSelf .eq) inputs trivial)

/-- `logical/rule09`: exact comparison with actual pointwise Min/Max. -/
theorem less_than_minimum {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ Bool.and
        (Tensor.map₂ (fun a b => decide (a < b)) (inputs 0) (inputs 1))
        (Tensor.map₂ (fun a b => decide (b < a)) (inputs 2) (inputs 0)) =
      Tensor.map₂ (fun a b => decide (a < b)) (inputs 0)
        (Tensor.map₂ min (inputs 1) (inputs 2)) := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound (Rule.tautological false true) inputs trivial)

/-- `logical/rule10`: exact comparison with actual pointwise Min/Max. -/
theorem max_gt_second {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (b < a)) (Tensor.map₂ max (inputs 0) (inputs 1))
        (inputs 1) = Tensor.map₂ (fun a b => decide (b < a)) (inputs 0) (inputs 1) := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound Rule.maxCompareSecond inputs trivial)

/-- `logical/rule11`: exact comparison with actual pointwise Min/Max. -/
theorem max_gt_first {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ (fun a b => decide (b < a)) (Tensor.map₂ max (inputs 0) (inputs 1))
        (inputs 0) = Tensor.map₂ (fun a b => decide (b < a)) (inputs 1) (inputs 0) := by
  apply Sum.inr.inj (α := Tensor shape α)
  simpa [Rule.lhs, Rule.rhs, Graph.eval, Predicate.eval, Expr.eval, Operations.exact] using
    (rewrite_sound Rule.maxCompareFirst inputs trivial)

/-- The paper artifact's Clamp applies Max to value/lower, then Min to upper/result. -/
def paperClamp {α : Type} [LinearOrder α] {rank : Nat} {shape : Shape rank}
    (lower value upper : Tensor shape α) : Tensor shape α :=
  Tensor.map₂ min upper (Tensor.map₂ max value lower)

/-- The existing Clamp definition and the paper's operand order agree under exact order. -/
theorem paperClamp_eq {α : Type} [LinearOrder α] {rank : Nat} {shape : Shape rank}
    (lower value upper : Tensor shape α) :
    paperClamp lower value upper = Tensor.map₂ min (Tensor.map₂ max value lower) upper := by
  funext index
  exact min_comm _ _

/-- `clamp/rule01`: applying the same Clamp twice is idempotent. -/
theorem clamp_idempotent {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    paperClamp (inputs 1) (paperClamp (inputs 1) (inputs 0) (inputs 2)) (inputs 2) =
      paperClamp (inputs 1) (inputs 0) (inputs 2) := by
  apply Sum.inl.inj (β := Tensor shape Bool)
  simpa [paperClamp_eq, Rule.lhs, Rule.rhs, Graph.eval, Expr.eval, Operations.exact] using
    (rewrite_sound Rule.clampIdempotent inputs trivial)

/-- `clamp/rule02`: Max above Min equals Clamp when the bounds are ordered. -/
theorem clamp_max_min {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) (ordered : ∀ index, inputs 1 index < inputs 2 index) :
    Tensor.map₂ max (inputs 1) (Tensor.map₂ min (inputs 0) (inputs 2)) =
      paperClamp (inputs 1) (inputs 0) (inputs 2) := by
  apply Sum.inl.inj (β := Tensor shape Bool)
  simpa [paperClamp_eq, Rule.lhs, Rule.rhs, Graph.eval, Expr.eval, Expr.minOrder, Expr.maxOrder,
    Operations.exact] using
    (rewrite_sound (Rule.maxMinClamp false false) inputs (fun index => le_of_lt (ordered index)))

/-- `clamp/rule03`: Min above Max is the paper's Clamp for arbitrary bounds. -/
theorem clamp_min_max {α : Type} [LinearOrder α] [Zero α] {rank : Nat} {shape : Shape rank}
    (inputs : Nat → Tensor shape α) :
    Tensor.map₂ min (inputs 2) (Tensor.map₂ max (inputs 0) (inputs 1)) =
      paperClamp (inputs 1) (inputs 0) (inputs 2) := by
  rfl

#print axioms self_gt
#print axioms self_lt
#print axioms self_ne
#print axioms self_ge
#print axioms self_le
#print axioms self_eq
#print axioms less_than_minimum
#print axioms max_gt_second
#print axioms max_gt_first

#print axioms clamp_idempotent
#print axioms clamp_max_min
#print axioms clamp_min_max

end TensorRewrite.PaperComparison.Comparisons
