module

public import TensorRewrite.Pilot.ReshapeLemmas
public import TensorRewrite.Pilot.IndexMaps

/-! Deleting one singleton axis while retaining every other extent and its original order. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.UnitAxis

open Pilot

/-- A rank-general description of one removed singleton and the surrounding retained axes. -/
inductive Plan : Nat → Type where
  /-- Remove the leading singleton and keep the complete trailing shape. -/
  | first {rank : Nat} (tail : Shape rank) : Plan rank
  /-- Keep one more leading extent before the singleton selected by the remaining plan. -/
  | keep {rank : Nat} (extent : Nat) (tail : Plan rank) : Plan (rank + 1)

/-- Original dimensions, with the selected singleton present. -/
def Plan.inputShape : {rank : Nat} → Plan rank → Shape (rank + 1)
  | _, .first tail => Fin.cases 1 tail
  | _, .keep extent tail => Fin.cases extent tail.inputShape

/-- The ordinary Reshape target shape after deleting exactly the chosen singleton. -/
def Plan.outputShape : {rank : Nat} → Plan rank → Shape rank
  | _, .first tail => tail
  | _, .keep extent tail => Fin.cases extent tail.outputShape

/-- Position of the original singleton axis. -/
def Plan.axis : {rank : Nat} → Plan rank → Fin (rank + 1)
  | _, .first _ => 0
  | _, .keep _ tail => tail.axis.succ

/-- Reinsert the chosen axis at a requested Broadcast output extent. -/
def Plan.targetShape : {rank : Nat} → Plan rank → Nat → Shape (rank + 1)
  | _, .first tail, copies => Fin.cases copies tail
  | _, .keep extent tail, copies => Fin.cases extent (tail.targetShape copies)

/-- Insert the actual zero coordinate at the removed singleton. -/
def Plan.insertIndex : {rank : Nat} → (plan : Plan rank) → Index plan.outputShape →
    Index plan.inputShape
  | _, .first _, index => Fin.cases ⟨0, by change 0 < 1; decide⟩ index
  | _, .keep _ tail, index =>
    Fin.cases (index 0) (tail.insertIndex (fun axis => index axis.succ))

/-- Project a Broadcast output onto the actual retained coordinates. -/
def Plan.projectIndex : {rank : Nat} → (plan : Plan rank) → {copies : Nat} →
    Index (plan.targetShape copies) → Index plan.outputShape
  | _, .first _, _, index => fun axis => index axis.succ
  | _, .keep _ tail, _, index =>
    Fin.cases (index 0) (tail.projectIndex (fun axis => index axis.succ))

/-- The ordered original-axis positions of the dimensions retained by deletion. -/
def Plan.axesMap : {rank : Nat} → (plan : Plan rank) → Fin rank → Fin (rank + 1)
  | _, .first _, axis => axis.succ
  | _, .keep _ tail, axis => Fin.cases 0 (fun axis => (tail.axesMap axis).succ) axis

/-- Actual signed Broadcast attributes, computed from the retained axis positions. -/
def Plan.broadcastAxes {rank : Nat} (plan : Plan rank) :
    IndexMaps.BroadcastAxes rank (rank + 1) where
  values := Vector.ofFn (fun axis => ((plan.axesMap axis).val : Int))
  valid axis := by
    simp only [Fin.getElem_fin, Vector.getElem_ofFn]
    have bound := (plan.axesMap axis).isLt
    omega

/-- Construct the deletion plan for any legal axis, preserving every other supplied dimension. -/
def ofAxis : {rank : Nat} → Shape (rank + 1) → Fin (rank + 1) → Plan rank
  | 0, _, _ => .first Fin.elim0
  | _rank + 1, shape, axis =>
    Fin.cases (.first (fun axis => shape axis.succ))
      (fun axis => .keep (shape 0) (ofAxis (fun axis => shape axis.succ) axis)) axis

end TensorRewrite.Theory.UnitAxis
