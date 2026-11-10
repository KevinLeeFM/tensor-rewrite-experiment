module

public import TensorRewrite.Pilot.EffectfulBooleanDagLemmas
public import TensorRewrite.Pilot.Boolean

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.EffectfulBooleanDag

open Dag

variable {rank : Nat} {shape : Shape rank} {scope : Nat} {External State Error : Type}
  (body : Program (BooleanDag.Opcode ⊕ External) (scope + 1))
  (inputs : Nat → Except Error (Tensor shape Bool)) (env : Fin scope → Tensor shape Bool)
  (external : External → List (Tensor shape Bool) → State → Outcome (Tensor shape Bool) State Error)
  (invalidArity : Error) (state : State) (lhs rhs : Fin scope)

/-- Delete an And with a true rhs and redirect every use to its lhs. -/
theorem and_rhs_true (h : env rhs = Tensor.constant true) :
    (Program.bind (.operation (.inl .logicalAnd) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.and_rhs_true]

/-- Delete an And with a true lhs and redirect every use to its rhs. -/
theorem and_lhs_true (h : env lhs = Tensor.constant true) :
    (Program.bind (.operation (.inl .logicalAnd) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef rhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.and_lhs_true]

/-- Delete an And with a false rhs and redirect every use to that existing rhs. -/
theorem and_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalAnd) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef rhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.and_rhs_false]

/-- Delete an And with a false lhs and redirect every use to that existing lhs. -/
theorem and_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalAnd) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.and_lhs_false]

/-- Delete an Or with a true rhs and redirect every use to that rhs. -/
theorem or_rhs_true (h : env rhs = Tensor.constant true) :
    (Program.bind (.operation (.inl .logicalOr) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef rhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.or_rhs_true]

/-- Delete an Or with a true lhs and redirect every use to that lhs. -/
theorem or_lhs_true (h : env lhs = Tensor.constant true) :
    (Program.bind (.operation (.inl .logicalOr) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.or_lhs_true]

/-- Delete an Or with a false rhs and redirect every use to its lhs. -/
theorem or_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalOr) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.or_rhs_false]

/-- Delete an Or with a false lhs and redirect every use to its rhs. -/
theorem or_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalOr) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef rhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.or_lhs_false]

/-- Delete an Xor with a false rhs and redirect every use to its lhs. -/
theorem xor_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalXor) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.xor (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.xor_rhs_zero]

/-- Delete an Xor with a false lhs and redirect every use to its rhs. -/
theorem xor_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation (.inl .logicalXor) [lhs, rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef rhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map₂ Bool.xor (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.xor_lhs_zero]

/-- Replace Xor of the same reference by an explicit new false constant node. -/
theorem xor_self :
    (Program.bind (.operation (.inl .logicalXor) [lhs, lhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (Program.bind (.operation (.inl (.constant false)) []) body).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_replace_of_pure
  change some (Tensor.map₂ Bool.xor (env lhs) (env lhs)) = some (Tensor.constant false)
  rw [Boolean.xor_self]

/-- Delete outer Not when its input is the negation of the existing replacement. -/
theorem not_not (h : env rhs = Tensor.map Bool.not (env lhs)) :
    (Program.bind (.operation (.inl .logicalNot) [rhs]) body).evalEffectful
      (meaning shape external invalidArity) inputs env state =
      (body.mapInputs (dropRef lhs)).evalEffectful
      (meaning shape external invalidArity) inputs env state := by
  apply eval_delete_of_pure
  change some (Tensor.map Bool.not (env rhs)) = some (env lhs)
  rw [h, Boolean.not_not]

end TensorRewrite.Pilot.EffectfulBooleanDag
