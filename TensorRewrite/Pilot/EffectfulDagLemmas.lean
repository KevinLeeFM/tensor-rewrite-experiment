module

public import TensorRewrite.Pilot.EffectfulDag
public import TensorRewrite.Pilot.DagLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Dag

universe u v w e

variable {Op : Type u} {Value : Type v} {State : Type w} {Error : Type e}
  {scope target : Nat}

/-- Operand remapping preserves the entire stateful node outcome. -/
theorem Node.evalEffectful_mapRefs (node : Node Op scope) (refs : Fin scope → Fin target)
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin target → Value) (state : State) :
    (node.mapRefs refs).evalEffectful meaning inputs env state =
      node.evalEffectful meaning inputs (fun ref => env (refs ref)) state := by
  cases node <;> simp [Node.mapRefs, Node.evalEffectful, List.map_map, Function.comp_def]

/-- Renaming free references preserves successful and failing stateful evaluations. -/
theorem Program.evalEffectful_mapInputs (program : Program Op scope)
    (refs : Fin scope → Fin target)
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin target → Value) (state : State) :
    (program.mapInputs refs).evalEffectful meaning inputs env state =
      program.evalEffectful meaning inputs (fun ref => env (refs ref)) state := by
  induction program generalizing target state with
  | result ref => rfl
  | bind node body ih =>
    simp only [Program.mapInputs, Program.evalEffectful, Node.evalEffectful_mapRefs]
    cases step : node.evalEffectful meaning inputs (fun ref => env (refs ref)) state with
    | mk result nextState =>
      cases result with
      | error error => rfl
      | ok value =>
        change (body.mapInputs (liftRefs refs)).evalEffectful meaning inputs
          (extend value env) nextState =
            body.evalEffectful meaning inputs (extend value (fun ref => env (refs ref))) nextState
        rw [ih, extend_liftRefs]

/-- Deleting an equal-valued state-preserving node preserves arbitrary effectful suffixes. -/
theorem Program.evalEffectful_delete_equal (node : Node Op scope)
    (body : Program Op (scope + 1)) (replacement : Fin scope)
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin scope → Value) (state : State)
    (pure : node.evalEffectful meaning inputs env state = ⟨.ok (env replacement), state⟩) :
    (Program.bind node body).evalEffectful meaning inputs env state =
      (body.mapInputs (dropRef replacement)).evalEffectful meaning inputs env state := by
  rw [Program.evalEffectful_mapInputs]
  simp only [Program.evalEffectful, pure]
  change body.evalEffectful meaning inputs (extend (env replacement) env) state =
    body.evalEffectful meaning inputs (fun ref => env (dropRef replacement ref)) state
  congr 1
  funext ref
  refine Fin.cases ?_ (fun old => ?_) ref <;> rfl

/-- Equal node outcomes preserve every suffix, including error values and post-error state. -/
theorem Program.evalEffectful_replace_equal (before after : Node Op scope)
    (body : Program Op (scope + 1))
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin scope → Value) (state : State)
    (same : before.evalEffectful meaning inputs env state =
      after.evalEffectful meaning inputs env state) :
    (Program.bind before body).evalEffectful meaning inputs env state =
      (Program.bind after body).evalEffectful meaning inputs env state := by
  simp only [Program.evalEffectful]
  rw [same]

/-- An unused successful pure binding can be removed without changing future observations. -/
theorem Program.evalEffectful_delete_unused (node : Node Op scope) (body : Program Op scope)
    (meaning : Op → List Value → State → Outcome Value State Error)
    (inputs : Nat → Except Error Value) (env : Fin scope → Value) (state : State) (value : Value)
    (pure : node.evalEffectful meaning inputs env state = ⟨.ok value, state⟩) :
    (Program.bind node (body.mapInputs Fin.succ)).evalEffectful meaning inputs env state =
      body.evalEffectful meaning inputs env state := by
  simp only [Program.evalEffectful, pure]
  rw [Program.evalEffectful_mapInputs]
  rfl

end TensorRewrite.Pilot.Dag
