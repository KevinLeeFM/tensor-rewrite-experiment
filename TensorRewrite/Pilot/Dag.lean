module

public import Std

/-! A finite acyclic dataflow graph written in topological binding order.
References index the available prefix, newest first. Operators are pure and may
reject invalid operand lists. Metadata, control edges and effects are separate. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Dag

universe u v

/-- One graph node whose operand references are already in scope. -/
inductive Node (Op : Type u) (scope : Nat) where
  | parameter (index : Nat)
  | operation (opcode : Op) (operands : List (Fin scope))
deriving Repr

/-- A graph suffix, terminating in one result reference; repeated uses share nodes. -/
inductive Program (Op : Type u) : Nat → Type u where
  | result {scope : Nat} (ref : Fin scope) : Program Op scope
  | bind {scope : Nat} (node : Node Op scope) (body : Program Op (scope + 1)) :
      Program Op scope
deriving Repr

variable {Op : Type u} {Value : Type v} {scope target : Nat}

/-- Add the newly computed value at reference zero without copying old values. -/
def extend (value : Value) (env : Fin scope → Value) : Fin (scope + 1) → Value :=
  Fin.cases value env

/-- Lift a reference map through one new binding, keeping the new reference fixed. -/
def liftRefs (refs : Fin scope → Fin target) : Fin (scope + 1) → Fin (target + 1) :=
  Fin.cases 0 (fun ref => (refs ref).succ)

/-- Delete the newest binding and redirect all its uses to an existing reference. -/
def dropRef (replacement : Fin scope) : Fin (scope + 1) → Fin scope :=
  Fin.cases replacement id

/-- Remap the operands of a node; parameter numbers are external and unchanged. -/
def Node.mapRefs (refs : Fin scope → Fin target) : Node Op scope → Node Op target
  | .parameter index => .parameter index
  | .operation opcode operands => .operation opcode (operands.map refs)

/-- Remap free prefix references throughout a graph suffix, including its result. -/
def Program.mapInputs : {scope target : Nat} → (Fin scope → Fin target) →
    Program Op scope → Program Op target
  | _, _, refs, .result ref => .result (refs ref)
  | _, _, refs, .bind node body => .bind (node.mapRefs refs) (body.mapInputs (liftRefs refs))

/-- Evaluate a pure node, returning none for an absent parameter or invalid operation. -/
def Node.eval (meaning : Op → List Value → Option Value) (inputs : Nat → Option Value)
    (env : Fin scope → Value) : Node Op scope → Option Value
  | .parameter index => inputs index
  | .operation opcode operands => meaning opcode (operands.map env)

/-- Evaluate each binding once; uses read its shared value from the environment. -/
def Program.eval (meaning : Op → List Value → Option Value) (inputs : Nat → Option Value) :
    {scope : Nat} → Program Op scope → (Fin scope → Value) → Option Value
  | _, .result ref, env => some (env ref)
  | _, .bind node body, env => do
    let value ← node.eval meaning inputs env
    body.eval meaning inputs (extend value env)

end TensorRewrite.Pilot.Dag
