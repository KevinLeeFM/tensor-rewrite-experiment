module

public import TensorRewrite.Pilot.ConstantGuardLemmas
public import TensorRewrite.Pilot.BooleanDagRules

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.BooleanDag

open Dag ConstantGuard

/-- The modeled IsAll guard discharges the constant premise of graph And elimination. -/
theorem and_rhs_true_of_isAll {rank : Nat} {shape : Shape rank} {scope : Nat}
    (body : Program Opcode (scope + 1)) (inputs : Nat → Option (Tensor shape Bool))
    (views : Fin scope → View rank shape) (lhs rhs : Fin scope)
    (guard : (views rhs).isAll true = true) :
    (Program.bind (.operation .logicalAnd [lhs, rhs]) body).eval (meaning shape) inputs
        (fun ref => (views ref).eval) =
      (body.mapInputs (dropRef lhs)).eval (meaning shape) inputs
        (fun ref => (views ref).eval) := by
  exact and_rhs_true body inputs (fun ref => (views ref).eval) lhs rhs
    ((views rhs).isAll_sound true guard)

end TensorRewrite.Pilot.BooleanDag
