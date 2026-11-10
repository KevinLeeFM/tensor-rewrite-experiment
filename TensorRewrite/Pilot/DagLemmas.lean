module

public import TensorRewrite.Pilot.Dag

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Dag

universe u v

variable {Op : Type u} {Value : Type v} {scope target : Nat}

/-- Remapping operands agrees with reading the corresponding old environment. -/
theorem Node.eval_mapRefs (node : Node Op scope) (refs : Fin scope → Fin target)
    (meaning : Op → List Value → Option Value) (inputs : Nat → Option Value)
    (env : Fin target → Value) :
    (node.mapRefs refs).eval meaning inputs env =
      node.eval meaning inputs (fun ref => env (refs ref)) := by
  cases node <;> simp [Node.mapRefs, Node.eval, List.map_map, Function.comp_def]

/-- Reference lifting commutes with extending an environment by the new value. -/
theorem extend_liftRefs (refs : Fin scope → Fin target) (value : Value)
    (env : Fin target → Value) :
    (fun ref => extend value env (liftRefs refs ref)) =
      extend value (fun ref => env (refs ref)) := by
  funext ref
  refine Fin.cases ?_ (fun old => ?_) ref <;> rfl

/-- Renaming every free reference preserves evaluation under the matching environment. -/
theorem Program.eval_mapInputs (program : Program Op scope) (refs : Fin scope → Fin target)
    (meaning : Op → List Value → Option Value) (inputs : Nat → Option Value)
    (env : Fin target → Value) :
    (program.mapInputs refs).eval meaning inputs env =
      program.eval meaning inputs (fun ref => env (refs ref)) := by
  induction program generalizing target with
  | result ref => rfl
  | bind node body ih =>
    simp only [Program.mapInputs, Program.eval, Node.eval_mapRefs]
    cases h : node.eval meaning inputs (fun ref => env (refs ref)) with
    | none => rfl
    | some value =>
      change (body.mapInputs (liftRefs refs)).eval meaning inputs (extend value env) =
        body.eval meaning inputs (extend value (fun ref => env (refs ref)))
      rw [ih, extend_liftRefs]

/-- Replacing a successful node by an equal-valued earlier node preserves every suffix. -/
theorem Program.eval_delete_equal (node : Node Op scope) (body : Program Op (scope + 1))
    (replacement : Fin scope) (meaning : Op → List Value → Option Value)
    (inputs : Nat → Option Value) (env : Fin scope → Value)
    (h : node.eval meaning inputs env = some (env replacement)) :
    (Program.bind node body).eval meaning inputs env =
      (body.mapInputs (dropRef replacement)).eval meaning inputs env := by
  rw [Program.eval_mapInputs]
  simp only [Program.eval, h]
  change body.eval meaning inputs (extend (env replacement) env) =
    body.eval meaning inputs (fun ref => env (dropRef replacement ref))
  congr 1
  funext ref
  refine Fin.cases ?_ (fun old => ?_) ref <;> rfl

/-- Replacing a node's operation preserves its suffix when its partial value agrees. -/
theorem Program.eval_replace_equal (before after : Node Op scope)
    (body : Program Op (scope + 1)) (meaning : Op → List Value → Option Value)
    (inputs : Nat → Option Value) (env : Fin scope → Value)
    (h : before.eval meaning inputs env = after.eval meaning inputs env) :
    (Program.bind before body).eval meaning inputs env =
      (Program.bind after body).eval meaning inputs env := by
  simp only [Program.eval]
  rw [h]

end TensorRewrite.Pilot.Dag
