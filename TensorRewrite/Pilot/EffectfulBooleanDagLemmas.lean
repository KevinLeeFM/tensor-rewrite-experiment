module

public import TensorRewrite.Pilot.EffectfulBooleanDag
public import TensorRewrite.Pilot.EffectfulDagLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.EffectfulBooleanDag

open Dag

variable {rank : Nat} {shape : Shape rank} {scope : Nat} {External State Error : Type}
  (body : Program (BooleanDag.Opcode ⊕ External) (scope + 1))
  (inputs : Nat → Except Error (Tensor shape Bool)) (env : Fin scope → Tensor shape Bool)
  (external : External → List (Tensor shape Bool) → State → Outcome (Tensor shape Bool) State Error)
  (invalidArity : Error) (state : State)

/-- A pure node-value proof lifts to a state/error-preserving contextual deletion. -/
theorem eval_delete_of_pure (opcode : BooleanDag.Opcode) (operands : List (Fin scope))
    (replacement : Fin scope)
    (pure : BooleanDag.meaning shape opcode (operands.map env) = some (env replacement)) :
    (Program.bind (.operation (.inl opcode) operands) body).evalEffectful
        (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef replacement)).evalEffectful
        (meaning shape external invalidArity) inputs env state := by
  apply Program.evalEffectful_delete_equal
  simp only [Node.evalEffectful, meaning, pure]

/-- Equality of pure partial meanings lifts to an effectful contextual node replacement. -/
theorem eval_replace_of_pure (before after : BooleanDag.Opcode)
    (beforeOperands afterOperands : List (Fin scope))
    (same : BooleanDag.meaning shape before (beforeOperands.map env) =
      BooleanDag.meaning shape after (afterOperands.map env)) :
    (Program.bind (.operation (.inl before) beforeOperands) body).evalEffectful
        (meaning shape external invalidArity) inputs env state =
      (Program.bind (.operation (.inl after) afterOperands) body).evalEffectful
        (meaning shape external invalidArity) inputs env state := by
  apply Program.evalEffectful_replace_equal
  simp only [Node.evalEffectful, meaning, same]

end TensorRewrite.Pilot.EffectfulBooleanDag
