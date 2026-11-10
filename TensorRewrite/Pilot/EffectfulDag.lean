module

public import TensorRewrite.Pilot.Dag

/-! Evaluation of a fixed topological DAG schedule with arbitrary state and
explicit failures. A failure retains the state produced before it occurred. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Dag

universe u v w e

/-- Observable result and state, including state accumulated before a failure. -/
structure Outcome (Value : Type v) (State : Type w) (Error : Type e) where
  /-- Successful value or the exact error value. -/
  result : Except Error Value
  /-- State after this evaluation, even when the result is an error. -/
  state : State
deriving Repr

/-- Evaluate one node, keeping parameter lookup pure and exposing operator state transitions. -/
def Node.evalEffectful {Op : Type u} {Value : Type v} {State : Type w} {Error : Type e}
    {scope : Nat} (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin scope → Value) :
    Node Op scope → State → Outcome Value State Error
  | .parameter index, state => ⟨inputs index, state⟩
  | .operation opcode operands, state => meaning opcode (operands.map env) state

/-- Run bindings once in their recorded order; stop on failure without discarding state. -/
def Program.evalEffectful {Op : Type u} {Value : Type v} {State : Type w} {Error : Type e}
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) :
    {scope : Nat} → Program Op scope → (Fin scope → Value) → State → Outcome Value State Error
  | _, .result ref, env, state => ⟨.ok (env ref), state⟩
  | _, .bind node body, env, state =>
    let step := node.evalEffectful meaning inputs env state
    match step.result with
    | .error error => ⟨.error error, step.state⟩
    | .ok value => body.evalEffectful meaning inputs (extend value env) step.state

end TensorRewrite.Pilot.Dag
