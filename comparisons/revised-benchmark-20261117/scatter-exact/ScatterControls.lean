module
public import ScatterProof
public section
set_option autoImplicit false
namespace RevisedBenchmark.ScatterExact
open TensorRewrite.Pilot.ReducerIndex.ScatterRoles
private def extra (i : Fin 2) : BitVec 8 := if i = 0 then 0 else 17
example (left : Bool) (a : Parameter) :
    original left a a extra (fun _ => 254) 0 4 = replacement left a a extra (fun _ => 254) 0 4 :=
  (correct ..).mpr (Or.inr rfl)
example : original true .update .update extra (fun _ => 6) 1 5 1 = 27#8 ∧
    replacement true .update .update extra (fun _ => 6) 1 5 1 = 10#8 := by decide
example : original false .current .current extra (fun _ => 6) 1 5 1 = 29#8 ∧
    replacement false .current .current extra (fun _ => 6) 1 5 1 = 46#8 := by decide
example (left : Bool) (a b : Parameter) (e base : Fin 1 → BitVec 0) (u : BitVec 0) :
    original left a b e base 0 u = replacement left a b e base 0 u :=
  (correct ..).mpr (Or.inr (Subsingleton.elim _ _))
end RevisedBenchmark.ScatterExact
