module

public import TensorRewrite.Theory.ScatterConcatLemmas
public import TensorRewrite.Theory.ReductionFiberLemmas

/-! Scatter input layouts with interleaved batch/window axes and inserted singleton windows. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterLayout

open Pilot

/-- Insert any number of singleton operand-window axes into an actual compact window shape.
Retained window axes keep their original relative order. -/
inductive WindowEmbedding : {rank : Nat} → Shape rank → Type where
  | scalar : WindowEmbedding (Fin.elim0 : Shape 0)
  | insert {rank : Nat} {shape : Shape rank} (tail : WindowEmbedding shape) :
      WindowEmbedding shape
  | keep {rank : Nat} {shape : Shape rank} (extent : Nat) (tail : WindowEmbedding shape) :
      WindowEmbedding (Fin.cases extent shape)

/-- Operand rank after inserting all the singleton window axes. -/
def WindowEmbedding.fullRank : {rank : Nat} → {shape : Shape rank} →
    WindowEmbedding shape → Nat
  | _, _, .scalar => 0
  | _, _, .insert tail | _, _, .keep _ tail => tail.fullRank + 1

/-- Full-rank window extents, with one at every inserted operand dimension. -/
def WindowEmbedding.fullShape : {rank : Nat} → {shape : Shape rank} →
    (embedding : WindowEmbedding shape) → Shape embedding.fullRank
  | _, _, .scalar => Fin.elim0
  | _, _, .insert tail => Fin.cases 1 tail.fullShape
  | _, _, .keep extent tail => Fin.cases extent tail.fullShape

/-- Expand a compact update-window coordinate by inserting bounded zeros. -/
def WindowEmbedding.expandIndex : {rank : Nat} → {shape : Shape rank} →
    (embedding : WindowEmbedding shape) → Index shape → Index embedding.fullShape
  | _, _, .scalar, _ => fun axis => Fin.elim0 axis
  | _, _, .insert tail, index => Fin.cases ⟨0, by change 0 < 1; decide⟩ (tail.expandIndex index)
  | _, _, .keep _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩)
      (tail.expandIndex (fun axis => index axis.succ))

/-- Project a full-rank window coordinate onto the actual retained update-window dimensions. -/
def WindowEmbedding.projectIndex : {rank : Nat} → {shape : Shape rank} →
    (embedding : WindowEmbedding shape) → Index embedding.fullShape → Index shape
  | _, _, .scalar, _ => fun axis => Fin.elim0 axis
  | _, _, .insert tail, index => tail.projectIndex (fun axis => index axis.succ)
  | _, _, .keep _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩)
      (tail.projectIndex (fun axis => index axis.succ))

/-- Actual update-axis partition and inserted operand dimensions. Kept update axes are batch
axes; reduced update axes are window axes. No reduction is performed on the update values. -/
structure Plan (indexSize : Nat) where
  updateAxes : Reduction.Plan
  windows : WindowEmbedding (ReductionFiber.shape updateAxes)
  operandShape : Shape windows.fullRank
  indexAxes : IndexMaps.BroadcastAxes indexSize windows.fullRank
  injective : Function.Injective indexAxes.decode

/-- The shared full-rank geometry, derived from the actual compact update layout. -/
abbrev Plan.toOrdered {indexSize : Nat} (plan : Plan indexSize) :
    OrderedScatter.Plan plan.windows.fullRank plan.updateAxes.outputRank indexSize where
  operandShape := plan.operandShape
  batchShape := plan.updateAxes.outputShape
  windowShape := plan.windows.fullShape
  indexAxes := plan.indexAxes
  injective := plan.injective

/-- Read the original update tensor at the bounded merged batch/window coordinate.
Singleton operand-window coordinates are removed, never used as extra update axes. -/
def adaptUpdates {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (updates : Tensor plan.updateAxes.inputShape α) :
    Tensor plan.updateAxes.outputShape (Tensor plan.windows.fullShape α) := fun batch window =>
  updates (ReductionFiber.mergeIndex plan.updateAxes batch (plan.windows.projectIndex window))

/-- Generate actual batch-major/compact-window-major events from the interleaved update tensor.
This declared order is independent of the tensor's raw row-major storage enumeration. -/
def entries {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    List (OrderedScatter.Entry plan.operandShape α) :=
  (OrderedCoordinates.enumerate plan.updateAxes.outputShape).flatMap fun batch =>
    (OrderedCoordinates.enumerate (ReductionFiber.shape plan.updateAxes)).map fun window =>
      ⟨OrderedScatter.target? plan.toOrdered indices batch (plan.windows.expandIndex window),
        updates (ReductionFiber.mergeIndex plan.updateAxes batch window)⟩

/-- Apply the declared ordered Scatter directly to the actual interleaved update tensor. -/
def scatter {indexSize : Nat} {α : Type} (plan : Plan indexSize) (operation : α → α → α)
    (base : Tensor plan.operandShape α)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) : Tensor plan.operandShape α :=
  OrderedScatter.run operation base (entries plan indices updates)

end TensorRewrite.Theory.ScatterLayout
