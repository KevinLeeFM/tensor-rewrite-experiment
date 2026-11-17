module
public import TensorRewrite.Pilot.ReducerIndexLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ScatterExact
open TensorRewrite.Pilot.ReducerIndex.ScatterRoles

/-- Preserve the order of the outer Add operands in both callers. -/
def original {n w : Nat} (scatterLeft : Bool) (a b : Parameter) (extra base : Fin n → BitVec w)
    (t : Fin n) (u : BitVec w) : Fin n → BitVec w :=
  if scatterLeft then fun i => scatter a b base t u i + extra i else before a b extra base t u

/-- The changed Scatter base retains the operand order of the source branch. -/
def replacement {n w : Nat} (scatterLeft : Bool) (a b : Parameter) (extra base : Fin n → BitVec w)
    (t : Fin n) (u : BitVec w) : Fin n → BitVec w :=
  if scatterLeft then scatter a b (fun i => base i + extra i) t u else after a b extra base t u

def Goal : Prop :=
  ∀ {n w : Nat} (scatterLeft : Bool) (a b : Parameter) (extra base : Fin n → BitVec w)
    (t : Fin n) (u : BitVec w),
    original scatterLeft a b extra base t u = replacement scatterLeft a b extra base t u ↔
      a ≠ b ∨ extra t = 0
end RevisedBenchmark.ScatterExact
