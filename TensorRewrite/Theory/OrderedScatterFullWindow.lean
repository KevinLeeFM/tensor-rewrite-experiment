module

public import TensorRewrite.Theory.OrderedScatterGeometry

/-! Derive the actual event list and one-hit property of a full window with no index components. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- The scalar-batch zero-vector source emits the full original coordinate enumeration once. -/
theorem entries_full_window {rank : Nat} {α : Type} (shape : Shape rank)
    (indices : Tensor (fullWindowPlan shape).batchShape (Fin 0 → Int))
    (updates : Tensor (fullWindowPlan shape).batchShape (Tensor shape α)) :
    entries (fullWindowPlan shape) indices updates =
      (List.finRange (LinearIndex.elementCount shape)).map fun position =>
        let index := LinearIndex.delinearize shape position
        (⟨some index, updates (fun axis => Fin.elim0 axis) index⟩ : Entry shape α) := by
  unfold entries
  change (List.finRange 1).flatMap (fun _ : Fin 1 =>
    (List.finRange (LinearIndex.elementCount shape)).map fun position =>
      (⟨target? (fullWindowPlan shape) indices (fun axis => Fin.elim0 axis)
          (LinearIndex.delinearize shape position),
        updates (fun axis => Fin.elim0 axis) (LinearIndex.delinearize shape position)⟩ :
        Entry shape α)) = _
  simp only [show List.finRange 1 = ([0] : List (Fin 1)) from rfl, List.flatMap_singleton]
  apply List.map_congr_left
  intro position _
  rw [full_window_target]

/-- Every actual full-window output sees exactly its one corresponding update value. -/
theorem values_full_window {rank : Nat} {α : Type} (shape : Shape rank)
    (indices : Tensor (fullWindowPlan shape).batchShape (Fin 0 → Int))
    (updates : Tensor (fullWindowPlan shape).batchShape (Tensor shape α)) (index : Index shape) :
    valuesAt (entries (fullWindowPlan shape) indices updates) index =
      [updates (fun axis => Fin.elim0 axis) index] := by
  rw [entries_full_window]
  change ((List.finRange (LinearIndex.elementCount shape)).map (fun position =>
      (⟨some (LinearIndex.delinearize shape position),
        updates (fun axis => Fin.elim0 axis) (LinearIndex.delinearize shape position)⟩ :
        Entry shape α))).filterMap (fun entry =>
      if entry.target = some index then some entry.value else none) = _
  rw [List.filterMap_map]
  have same (position : Fin (LinearIndex.elementCount shape)) :
      LinearIndex.delinearize shape position = index ↔
        position = LinearIndex.linearize shape index := by
    constructor
    · intro equal
      simpa only [LinearIndex.linearize_delinearize] using congrArg
        (LinearIndex.linearize shape) equal
    · intro equal
      rw [equal, LinearIndex.delinearize_linearize]
  simp only [Function.comp_apply, Option.some.injEq]
  simp_rw [same]
  rw [filterMap_finRange_single, LinearIndex.delinearize_linearize]

end TensorRewrite.Theory.OrderedScatter
