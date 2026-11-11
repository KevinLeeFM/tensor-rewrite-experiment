module

public import TensorRewrite.Pilot.ReductionLemmas
public import TensorRewrite.Theory.FiniteSum

/-! Bounded coordinate decomposition for the existing ordered reduction plan. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ReductionFiber

open Pilot Pilot.Reduction

/-- Number of reduced axes; retained axes do not contribute. -/
def rank : Plan → Nat
  | .scalar => 0
  | .keep _ tail => rank tail
  | .reduce _ tail => rank tail + 1

/-- Extents of reduced axes, in their original relative order. -/
def shape : (plan : Plan) → Shape (rank plan)
  | .scalar => Fin.elim0
  | .keep _ tail => shape tail
  | .reduce extent tail => Fin.cases extent (shape tail)

/-- Merge kept and reduced coordinates in their original axis positions. -/
def mergeIndex : (plan : Plan) → Index plan.outputShape → Index (shape plan) →
    Index plan.inputShape
  | .scalar, _, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, output, reduced =>
    Fin.cases (output ⟨0, Nat.zero_lt_succ _⟩)
      (mergeIndex tail (fun axis => output axis.succ) reduced)
  | .reduce _ tail, output, reduced =>
    Fin.cases (reduced ⟨0, Nat.zero_lt_succ _⟩)
      (mergeIndex tail output (fun axis => reduced axis.succ))

/-- Project an input coordinate onto the kept axes. -/
def outputIndex : (plan : Plan) → Index plan.inputShape → Index plan.outputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, input =>
    Fin.cases (input ⟨0, Nat.zero_lt_succ _⟩) (outputIndex tail (fun axis => input axis.succ))
  | .reduce _ tail, input => outputIndex tail (fun axis => input axis.succ)

/-- Project an input coordinate onto the reduced axes. -/
def reducedIndex : (plan : Plan) → Index plan.inputShape → Index (shape plan)
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep _ tail, input => reducedIndex tail (fun axis => input axis.succ)
  | .reduce _ tail, input =>
    Fin.cases (input ⟨0, Nat.zero_lt_succ _⟩) (reducedIndex tail (fun axis => input axis.succ))

end TensorRewrite.Theory.ReductionFiber
