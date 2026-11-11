module

public import TensorRewrite.Theory.ControlValuesProof

/-! Observation and operand-selection diagnostics. These operational examples do not claim that
an external compiler permits the mutation or discards these observations.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ControlValues

/-- A scalar result with the ordered events of its computation. -/
structure Observed (α : Type) where
  value : α
  events : List Nat
deriving DecidableEq, Repr

/-- Eagerly evaluate predicate/left/right computations in that order before choosing a value. -/
def eagerSelect {α : Type} (predicate : Observed Bool) (left right : Observed α) : Observed α :=
  ⟨if predicate.value then left.value else right.value,
    predicate.events ++ left.events ++ right.events⟩

/-- A constant-root unary Map retains the operand computation in the eager observation model. -/
def eagerConstantMap {α β : Type} (input : Observed α) (value : β) : Observed β :=
  ⟨value, input.events⟩

/-- Changing greater-than selection to conjunction fails already at true and false. -/
theorem select_direction_refuted :
    (if compare .gt true false then true else false) ≠ (true && false) := by decide

/-- Reordering the selected Map operands changes an ordinary noncommutative scalar body. -/
theorem map_parameter_order_refuted :
    ((7 : Int) - 9) ≠ (9 - 7) := by decide

/-- Dropping a false branch preserves the selected value but can discard an event. -/
theorem select_effect_drop_refuted :
    eagerSelect ⟨true, []⟩ ⟨(7 : Nat), []⟩ ⟨9, [3]⟩ ≠ ⟨7, []⟩ := by decide

/-- Exchanging value branches can also exchange their eager execution events. -/
theorem select_effect_swap_refuted :
    eagerSelect ⟨false, []⟩ ⟨(7 : Nat), [1]⟩ ⟨9, [2]⟩ ≠
      eagerSelect ⟨true, []⟩ ⟨9, [2]⟩ ⟨7, [1]⟩ := by decide

/-- Constant-root value equality does not justify removing an operand computation. -/
theorem map_effect_drop_refuted :
    eagerConstantMap ⟨(9 : Nat), [4]⟩ (7 : Nat) ≠ ⟨7, []⟩ := by decide

/-- Keeping the wrong branch order changes a trace even when both branches return seven. -/
theorem conditional_branch_order_refuted :
    indexedConditional (booleanIndex true) (fun _ => ())
        (fun branch _ => (⟨7, [branch.val]⟩ : Observed Nat)) ≠
      predicateConditional true () (fun _ => (⟨7, [0]⟩ : Observed Nat))
        () (fun _ => ⟨7, [1]⟩) := by decide

end TensorRewrite.Theory.ControlValues
