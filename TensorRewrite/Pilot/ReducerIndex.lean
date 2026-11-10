module

public import TensorRewrite.Pilot.Tensor

/-! Value models for a single in-bounds Scatter update and signed Gather literals.
These expose parameter roles and literal conversion rather than assuming that
an Add of arbitrary Parameter nodes is the ordinary two-argument addition. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.ReducerIndex

namespace ScatterRoles

/-- The two legal scalar argument roles of the update computation. -/
inductive Parameter where
  | current | update
  deriving DecidableEq, Repr

/-- Read the actual selected parameter, including a repeated role. -/
def parameterValue {width : Nat} (role : Parameter) (old update : BitVec width) : BitVec width :=
  match role with | .current => old | .update => update

/-- The source matcher permits both parameter roles to be identical. -/
def combine {width : Nat} (first second : Parameter) (old update : BitVec width) : BitVec width :=
  parameterValue first old update + parameterValue second old update

/-- One legal in-bounds rank-one Scatter update; unrelated elements retain their base value. -/
def scatter {size width : Nat} (first second : Parameter) (base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) : Fin size → BitVec width := fun index =>
  if index = target then combine first second (base index) update else base index

/-- Original Add of a separate vector and Scatter result. -/
def before {size width : Nat} (first second : Parameter) (lhs base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) : Fin size → BitVec width := fun index =>
  lhs index + scatter first second base target update index

/-- Replacing the Scatter base with Add(lhs,base) changes the reducer's current-value argument. -/
def after {size width : Nat} (first second : Parameter) (lhs base : Fin size → BitVec width)
    (target : Fin size) (update : BitVec width) : Fin size → BitVec width :=
  scatter first second (fun index => lhs index + base index) target update

end ScatterRoles

namespace GatherLiterals

/-- Original rank-one scalar Gather chooses the clamped signed coordinate. -/
def originalIndex {width : Nat} (extent : Nat) (index : BitVec width) : Nat :=
  min (extent - 1) index.toInt.toNat

/-- A generated signed literal is narrowed at the actual index width before comparison. -/
def choose {width : Nat} (index : BitVec width) (previous position : Nat) : Nat :=
  if index.toInt ≥ (BitVec.ofNat width position).toInt then position else previous

/-- Source Select chain, including its initial element-zero result and iteration at zero. -/
def selectedIndex {width : Nat} (extent : Nat) (index : BitVec width) : Nat :=
  (List.range extent).foldl (choose index) 0

end GatherLiterals
end TensorRewrite.Pilot.ReducerIndex
