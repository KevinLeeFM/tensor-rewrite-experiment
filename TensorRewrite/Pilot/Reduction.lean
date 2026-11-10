module

public import TensorRewrite.Pilot.LinearIndex

/-! Static single-output reduction through an ordered axis plan. This specifies
one logical fold order; floating reassociation and graph effects are separate. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Reduction

/-- Consume input axes in order, retaining or reducing each extent. -/
inductive Plan where
  | scalar
  | keep (extent : Nat) (tail : Plan)
  | reduce (extent : Nat) (tail : Plan)
deriving Repr, DecidableEq

/-- Number of input axes described by the plan. -/
def Plan.inputRank : Plan → Nat
  | .scalar => 0
  | .keep _ tail | .reduce _ tail => tail.inputRank + 1

/-- Number of axes retained in the result. -/
def Plan.outputRank : Plan → Nat
  | .scalar => 0
  | .keep _ tail => tail.outputRank + 1
  | .reduce _ tail => tail.outputRank

/-- Input extents in their original order. -/
def Plan.inputShape : (plan : Plan) → Shape plan.inputRank
  | .scalar => Fin.elim0
  | .keep extent tail | .reduce extent tail => Fin.cases extent tail.inputShape

/-- Result extents after removing precisely the reduced axes. -/
def Plan.outputShape : (plan : Plan) → Shape plan.outputRank
  | .scalar => Fin.elim0
  | .keep extent tail => Fin.cases extent tail.outputShape
  | .reduce _ tail => tail.outputShape

/-- Number of input elements belonging to each output coordinate. -/
def Plan.fiberCount : Plan → Nat
  | .scalar => 1
  | .keep _ tail => tail.fiberCount
  | .reduce extent tail => extent * tail.fiberCount

/-- All reduced axes have extent one; kept extents are unrestricted. -/
def Plan.UnitReducedAxes : Plan → Prop
  | .scalar => True
  | .keep _ tail => tail.UnitReducedAxes
  | .reduce extent tail => extent = 1 ∧ tail.UnitReducedAxes

/-- Insert the unique zero coordinate at every reduced unit axis. -/
def Plan.unitIndex : (plan : Plan) → plan.UnitReducedAxes →
    Index plan.outputShape → Index plan.inputShape
  | .scalar, _, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, units, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩)
      (tail.unitIndex units (fun axis => index axis.succ))
  | .reduce extent tail, units, index =>
    Fin.cases ⟨0, by
      change 0 < extent
      have one : extent = 1 := units.1
      omega⟩ (tail.unitIndex units.2 index)

/-- Enumerate a reduction fiber, fixing kept axes and varying reduced axes in order. -/
def fiberValues {α : Type} : (plan : Plan) → Tensor plan.inputShape α →
    Index plan.outputShape → List α
  | .scalar, input, _ => [input (fun axis => Fin.elim0 axis)]
  | .keep _ tail, input, output =>
    fiberValues tail (fun index => input (Fin.cases (output ⟨0, Nat.zero_lt_succ _⟩) index))
      (fun axis => output axis.succ)
  | .reduce extent tail, input, output =>
    (List.finRange extent).flatMap fun coordinate =>
      fiberValues tail (fun index => input (Fin.cases coordinate index)) output

/-- Fold each enumerated fiber with the actual initializer and binary operation. -/
def reduceTensor {α : Type} (plan : Plan) (operation : α → α → α) (initial : α)
    (input : Tensor plan.inputShape α) : Tensor plan.outputShape α :=
  fun output => (fiberValues plan input output).foldl operation initial

end TensorRewrite.Pilot.Reduction
