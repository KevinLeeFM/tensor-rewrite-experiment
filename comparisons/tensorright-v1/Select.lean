module

public import TensorRewrite.Theory.ControlValuesProof

/-! Paper-era Select identities over all values and finite tensor shapes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Select

open Pilot Theory.ControlValues

/-- `select/rule01`: equal branches return their common value. -/
theorem equal {α : Type} {rank : Nat} {shape : Shape rank}
    (predicate : Tensor shape Bool) (input : Tensor shape α) :
    select predicate input input = input := select_equal predicate input

/-- `select/rule02`: an all-true condition chooses the first branch. -/
theorem true_branch {α : Type} {rank : Nat} {shape : Shape rank}
    (onTrue onFalse : Tensor shape α) :
    select (Tensor.constant true) onTrue onFalse = onTrue := select_true onTrue onFalse

/-- `select/rule03`: an all-false condition chooses the second branch. -/
theorem false_branch {α : Type} {rank : Nat} {shape : Shape rank}
    (onTrue onFalse : Tensor shape α) :
    select (Tensor.constant false) onTrue onFalse = onFalse := select_false onTrue onFalse

/-- `select/rule04`: negation and branch reversal work for any predicate, including false. -/
theorem negate_condition {α : Type} {rank : Nat} {shape : Shape rank}
    (predicate : Tensor shape Bool) (onTrue onFalse : Tensor shape α) :
    select (Tensor.map Bool.not predicate) onTrue onFalse = select predicate onFalse onTrue :=
  select_not predicate onTrue onFalse

#print axioms equal
#print axioms true_branch
#print axioms false_branch
#print axioms negate_condition

end TensorRewrite.PaperComparison.Select
