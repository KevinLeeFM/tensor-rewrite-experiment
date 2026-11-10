import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Dag

namespace EffectfulControls

/-- A scalar tensor has one observable cell. -/
def shape : Shape 0 := Fin.elim0

/-- The scalar coordinate. -/
def index : Index shape := fun axis => Fin.elim0 axis

/-- External actions used to probe state retained on success and failure. -/
inductive Action where
  | emit
  | fail
  deriving Repr

/-- Distinguish operator failure, arity failure and missing inputs. -/
inductive Error where
  | stopped
  | arity
  | missing
  deriving Repr, DecidableEq

/-- Emit an operand-dependent event; failure also changes state before stopping. -/
def external : Action → List (Tensor shape Bool) → List Nat →
    Outcome (Tensor shape Bool) (List Nat) Error
  | .emit, [value], state => ⟨.ok value, state ++ [if value index then 1 else 0]⟩
  | .fail, _, state => ⟨.error .stopped, state ++ [9]⟩
  | _, _, state => ⟨.error .arity, state⟩

/-- False and true prefix values, respectively. -/
def env : Fin 2 → Tensor shape Bool :=
  Fin.cases (Tensor.constant false) (fun _ => Tensor.constant true)

/-- The rewritten value has two users, followed by a state-changing failure. -/
def failingBody : Program (BooleanDag.Opcode ⊕ Action) 3 :=
  .bind (.operation (.inr .emit) [0])
    (.bind (.operation (.inr .emit) [1])
      (.bind (.operation (.inr .fail) []) (.result 0)))

/-- Shared successful uses also test reference lifting across two new bindings. -/
def successfulBody : Program (BooleanDag.Opcode ⊕ Action) 3 :=
  .bind (.operation (.inr .emit) [0])
    (.bind (.operation (.inr .emit) [1]) (.result 0))

/-- Run an old or redirected program from a nonempty state. -/
def run (program : Program (BooleanDag.Opcode ⊕ Action) 2) :
    Outcome (Tensor shape Bool) (List Nat) Error :=
  program.evalEffectful (EffectfulBooleanDag.meaning shape external .arity)
    (fun _ => .error .missing) env [7]

/-- Observe only the scalar cell, preserving exact error and state. -/
def observe (outcome : Outcome (Tensor shape Bool) (List Nat) Error) :
    Except Error Bool × List Nat :=
  (outcome.result.map (fun value => value index), outcome.state)

example : observe (run (.bind (.operation (.inl .logicalAnd) [1, 0]) failingBody)) =
    (.error .stopped, [7, 0, 0, 9]) := by rfl

example : observe (run (failingBody.mapInputs (dropRef 0))) =
    (.error .stopped, [7, 0, 0, 9]) := by rfl

example : run (.bind (.operation (.inl .logicalAnd) [1, 0]) failingBody) =
    run (failingBody.mapInputs (dropRef 0)) := by
  exact EffectfulBooleanDag.and_rhs_false failingBody _ env external .arity [7] 1 0 rfl

example : observe (run (successfulBody.mapInputs (dropRef 0))) =
    (.ok false, [7, 0, 0]) := by rfl

example : observe (run ((Program.result 0 : Program (BooleanDag.Opcode ⊕ Action) 3).mapInputs
    (dropRef 0))) = (.ok false, [7]) := by rfl

example : observe (run (.bind (.parameter 99) (.result 0))) =
    (.error .missing, [7]) := by rfl

#eval IO.println ("EFFECTFUL_MODEL original=" ++ reprStr (observe (run
  (.bind (.operation (.inl .logicalAnd) [1, 0]) failingBody))))
#eval IO.println ("EFFECTFUL_MODEL redirected=" ++ reprStr (observe (run
  (failingBody.mapInputs (dropRef 0)))))
#eval IO.println ("EFFECTFUL_MODEL success=" ++ reprStr (observe (run
  (successfulBody.mapInputs (dropRef 0)))))
#eval IO.println ("ORDER_MODEL original=" ++ reprStr (DependencyOrder.eventTrace
  ControlOrder.originalLabels [0, 1, 2, 3, 4]))
#eval IO.println ("ORDER_MODEL replacement=" ++ reprStr (DependencyOrder.eventTrace
  ControlOrder.replacementLabels [0, 2, 1, 3]))

end EffectfulControls
