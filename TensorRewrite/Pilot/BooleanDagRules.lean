module

public import TensorRewrite.Pilot.BooleanDag
public import TensorRewrite.Pilot.Boolean
public import TensorRewrite.Pilot.DagLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.BooleanDag

open Dag

variable {rank : Nat} {shape : Shape rank} {scope : Nat}
  (body : Program Opcode (scope + 1)) (inputs : Nat → Option (Tensor shape Bool))
  (env : Fin scope → Tensor shape Bool) (lhs rhs : Fin scope)

/-- Delete an And with a true rhs and redirect every use to its lhs. -/
theorem and_rhs_true (h : env rhs = Tensor.constant true) :
    (Program.bind (.operation .logicalAnd [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.and_rhs_true]

/-- Delete an And with a true lhs and redirect every use to its rhs. -/
theorem and_lhs_true (h : env lhs = Tensor.constant true) :
    (Program.bind (.operation .logicalAnd [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef rhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.and_lhs_true]

/-- Delete an And with a false rhs and redirect every use to that existing rhs. -/
theorem and_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation .logicalAnd [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef rhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.and_rhs_false]

/-- Delete an And with a false lhs and redirect every use to that existing lhs. -/
theorem and_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation .logicalAnd [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.and (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.and_lhs_false]

/-- Delete an Or with a true rhs and redirect every use to that rhs. -/
theorem or_rhs_true (h : env rhs = Tensor.constant true) :
    (Program.bind (.operation .logicalOr [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef rhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.or_rhs_true]

/-- Delete an Or with a true lhs and redirect every use to that lhs. -/
theorem or_lhs_true (h : env lhs = Tensor.constant true) :
    (Program.bind (.operation .logicalOr [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.or_lhs_true]

/-- Delete an Or with a false rhs and redirect every use to its lhs. -/
theorem or_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation .logicalOr [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.or_rhs_false]

/-- Delete an Or with a false lhs and redirect every use to its rhs. -/
theorem or_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation .logicalOr [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef rhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.or (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.or_lhs_false]

/-- Delete an Xor with a false rhs and redirect every use to its lhs. -/
theorem xor_rhs_false (h : env rhs = Tensor.constant false) :
    (Program.bind (.operation .logicalXor [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.xor (env lhs) (env rhs)) = some (env lhs)
  rw [h, Boolean.xor_rhs_zero]

/-- Delete an Xor with a false lhs and redirect every use to its rhs. -/
theorem xor_lhs_false (h : env lhs = Tensor.constant false) :
    (Program.bind (.operation .logicalXor [lhs, rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef rhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map₂ Bool.xor (env lhs) (env rhs)) = some (env rhs)
  rw [h, Boolean.xor_lhs_zero]

/-- Replace Xor of the same reference by an explicit new false constant node. -/
theorem xor_self :
    (Program.bind (.operation .logicalXor [lhs, lhs]) body).eval (meaning shape) inputs env =
      (Program.bind (.operation (.constant false) []) body).eval (meaning shape) inputs env := by
  apply Program.eval_replace_equal
  change some (Tensor.map₂ Bool.xor (env lhs) (env lhs)) = some (Tensor.constant false)
  rw [Boolean.xor_self]

/-- Delete outer Not when its input is the negation of the existing replacement. -/
theorem not_not (h : env rhs = Tensor.map Bool.not (env lhs)) :
    (Program.bind (.operation .logicalNot [rhs]) body).eval (meaning shape) inputs env =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs env := by
  apply Program.eval_delete_equal
  change some (Tensor.map Bool.not (env rhs)) = some (env lhs)
  rw [h, Boolean.not_not]

end TensorRewrite.Pilot.BooleanDag
