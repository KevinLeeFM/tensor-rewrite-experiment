module

public import TensorRewrite.Theory.ScatterLayout

/-! Coordinate inverses and exact trace derivation for compact-window Scatter layouts. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterLayout

open Pilot

/-- Compact-coordinate projection recovers every original window coordinate after insertion. -/
theorem project_expand {rank : Nat} {shape : Shape rank} (embedding : WindowEmbedding shape)
    (index : Index shape) : embedding.projectIndex (embedding.expandIndex index) = index := by
  induction embedding with
  | scalar => funext axis; exact Fin.elim0 axis
  | insert tail ih => exact ih index
  | keep extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => index axis.succ)) axis

/-- Every full window coordinate is the expansion of its actual compact projection. -/
theorem expand_project {rank : Nat} {shape : Shape rank} (embedding : WindowEmbedding shape)
    (index : Index embedding.fullShape) :
    embedding.expandIndex (embedding.projectIndex index) = index := by
  induction embedding with
  | scalar => funext axis; exact Fin.elim0 axis
  | insert tail ih =>
    dsimp only [WindowEmbedding.fullRank, WindowEmbedding.fullShape] at index ⊢
    funext axis
    refine Fin.cases ?_ (fun axis => ?_) axis
    · apply Fin.ext
      have bound := (index 0).isLt
      change (index 0).val < 1 at bound
      change 0 = (index 0).val
      omega
    · exact congrFun (ih (fun axis => index axis.succ)) axis
  | keep extent tail ih =>
    funext axis
    refine Fin.cases rfl (fun axis => ?_) axis
    exact congrFun (ih (fun axis => index axis.succ)) axis

/-- Inserting singleton axes retains the exact original row-major coordinate list, with no
permutation or discarded empty-shape case. -/
theorem enumerate_expand {rank : Nat} {shape : Shape rank} (embedding : WindowEmbedding shape) :
    OrderedCoordinates.enumerate embedding.fullShape =
      (OrderedCoordinates.enumerate shape).map embedding.expandIndex := by
  induction embedding with
  | scalar => rfl
  | insert tail ih =>
    change OrderedCoordinates.enumerate (Fin.cases 1 tail.fullShape) = _
    rw [OrderedCoordinates.enumerate_uncons]
    change (List.finRange 1).flatMap (fun head =>
      (OrderedCoordinates.enumerate tail.fullShape).map fun rest =>
        (Fin.cases head rest : Index (WindowEmbedding.insert tail).fullShape)) = _
    rw [show List.finRange 1 = ([0] : List (Fin 1)) from rfl, List.flatMap_singleton, ih]
    simp only [List.map_map]
    rfl
  | keep extent tail ih =>
    change OrderedCoordinates.enumerate (Fin.cases extent tail.fullShape) = _
    rw [OrderedCoordinates.enumerate_uncons, OrderedCoordinates.enumerate_uncons]
    simp only [WindowEmbedding.fullShape, Fin.cases_zero, Fin.cases_succ]
    rw [ih]
    dsimp only [WindowEmbedding.fullRank, WindowEmbedding.fullShape, WindowEmbedding.expandIndex]
    simp only [List.map_flatMap, List.map_map]
    rfl

/-- Singleton insertion changes neither the number of updates nor the zero-window case. -/
theorem elementCount_full {rank : Nat} {shape : Shape rank} (embedding : WindowEmbedding shape) :
    LinearIndex.elementCount embedding.fullShape = LinearIndex.elementCount shape := by
  have same := congrArg List.length (enumerate_expand embedding)
  simpa only [OrderedCoordinates.enumerate, List.length_map, List.length_finRange] using same

/-- The actual merged update coordinate recovers both batch and compact window projections. -/
theorem update_coordinate {indexSize : Nat} (plan : Plan indexSize)
    (batch : Index plan.updateAxes.outputShape)
    (window : Index (ReductionFiber.shape plan.updateAxes)) :
    ReductionFiber.outputIndex plan.updateAxes (ReductionFiber.mergeIndex plan.updateAxes
      batch window) = batch ∧
    ReductionFiber.reducedIndex plan.updateAxes (ReductionFiber.mergeIndex plan.updateAxes
      batch window) = window :=
  ⟨ReductionFiber.output_merge _ _ _, ReductionFiber.reduced_merge _ _ _⟩

/-- Adapting the actual input tensor reads precisely its merged compact coordinate, not a
postulated or separately supplied tensor equality. -/
theorem adapt_expand {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (updates : Tensor plan.updateAxes.inputShape α) (batch : Index plan.updateAxes.outputShape)
    (window : Index (ReductionFiber.shape plan.updateAxes)) :
    adaptUpdates plan updates batch (plan.windows.expandIndex window) =
      updates (ReductionFiber.mergeIndex plan.updateAxes batch window) := by
  unfold adaptUpdates
  rw [project_expand]

/-- Scalar maps commute with the actual bounded update-layout adapter. -/
theorem adapt_map {indexSize : Nat} {α β : Type} (plan : Plan indexSize) (convert : α → β)
    (updates : Tensor plan.updateAxes.inputShape α) :
    adaptUpdates plan (Tensor.map convert updates) =
      fun batch => Tensor.map convert (adaptUpdates plan updates batch) := rfl

/-- The declared compact/interleaved evaluator emits exactly the full-rank evaluator's events
for the derived input adapter, including optional addresses, payloads and their order. -/
theorem entries_eq_ordered {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    entries plan indices updates =
      OrderedScatter.entries plan.toOrdered indices (adaptUpdates plan updates) := by
  rw [ScatterConcat.entries_coordinates, enumerate_expand]
  simp only [List.map_map]
  unfold entries
  apply List.flatMap_congr
  intro batch _
  apply List.map_congr_left
  intro window _
  change (⟨_, _⟩ : OrderedScatter.Entry plan.operandShape α) = ⟨_, _⟩
  rw [adapt_expand]

end TensorRewrite.Theory.ScatterLayout
