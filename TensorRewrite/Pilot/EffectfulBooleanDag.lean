module

public import TensorRewrite.Pilot.EffectfulDag
public import TensorRewrite.Pilot.BooleanDag

/-! Embed same-shape pure PRED operations into a language with arbitrary external
state/error transitions. This is a fixed-schedule model, not a control-edge or
mutable-IR metadata model. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.EffectfulBooleanDag

/-- Pure Boolean operations leave state unchanged; external operations supply their own outcomes. -/
def meaning {rank : Nat} (shape : Shape rank) {External State Error : Type}
    (external : External → List (Tensor shape Bool) → State →
      Dag.Outcome (Tensor shape Bool) State Error)
    (invalidArity : Error) :
    BooleanDag.Opcode ⊕ External → List (Tensor shape Bool) → State →
      Dag.Outcome (Tensor shape Bool) State Error
  | .inl opcode, operands, state =>
    match BooleanDag.meaning shape opcode operands with
    | some value => ⟨.ok value, state⟩
    | none => ⟨.error invalidArity, state⟩
  | .inr opcode, operands, state => external opcode operands state

end TensorRewrite.Pilot.EffectfulBooleanDag
