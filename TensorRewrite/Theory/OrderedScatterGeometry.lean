module

public import TensorRewrite.Theory.OrderedScatterLemmas

/-! Bounded target and event-count properties derived from actual Scatter attributes. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- The actual component at a mapped operand axis is recovered from the injective axis array. -/
theorem offset_mapped {rank batchRank indexSize : Nat} (plan : Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int)) (batch : Index plan.batchShape)
    (component : Fin indexSize) :
    offset plan indices batch (plan.indexAxes.decode component) = indices batch component := by
  cases found : (List.finRange indexSize).find?
      (fun candidate => plan.indexAxes.decode candidate = plan.indexAxes.decode component) with
  | none =>
    have absent := List.find?_eq_none.mp found
    have impossible := absent component (List.mem_finRange component)
    simp at impossible
  | some candidate =>
    have equal : plan.indexAxes.decode candidate = plan.indexAxes.decode component := by
      simpa only [decide_eq_true_eq] using List.find?_some found
    have same := plan.injective equal
    subst candidate
    simp only [offset, found]

/-- An operand axis absent from the actual index array has start zero. -/
theorem offset_unmapped {rank batchRank indexSize : Nat} (plan : Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int)) (batch : Index plan.batchShape)
    (axis : Fin rank) (absent : ∀ component, plan.indexAxes.decode component ≠ axis) :
    offset plan indices batch axis = 0 := by
  have missing : (List.finRange indexSize).find?
      (fun component => plan.indexAxes.decode component = axis) = none := by
    apply List.find?_eq_none.mpr
    intro component _
    simpa only [decide_eq_true_eq] using absent component
  simp only [offset, missing]

/-- A successful target is exactly the original start-plus-window coordinate on every axis. -/
theorem target_eq_some_iff {rank batchRank indexSize : Nat} (plan : Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int)) (batch : Index plan.batchShape)
    (window : Index plan.windowShape) (target : Index plan.operandShape) :
    target? plan indices batch window = some target ↔
      ∀ axis, offset plan indices batch axis + (window axis).val = (target axis).val := by
  rw [target?, LatticeIndex.assemble_eq_some_iff]
  apply forall_congr'
  intro axis
  simpa only [Int.natCast_one, mul_one] using
    LatticeIndex.decode_eq_some_iff (plan.operandShape axis) 1 (by decide)
      (offset plan indices batch axis + (window axis).val) (target axis)

/-- Actual trace length is the product of batch and full-window element counts. -/
theorem entries_length {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize) (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    (entries plan indices updates).length =
      LinearIndex.elementCount plan.batchShape * LinearIndex.elementCount plan.windowShape := by
  simp [entries, List.length_flatMap, List.sum_replicate]

/-- Zero batch count gives no event regardless of reducer coupling or value type. -/
theorem entries_empty_batch {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize) (empty : LinearIndex.elementCount plan.batchShape = 0)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    entries plan indices updates = [] := by
  simp [entries, empty]

/-- Zero window count gives no event, rather than a fabricated initializer update. -/
theorem entries_empty_window {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize) (empty : LinearIndex.elementCount plan.windowShape = 0)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    entries plan indices updates = [] := by
  simp [entries, empty]

/-- Empty index vectors mean actual start zero on every operand axis. -/
theorem empty_vector_offset {rank batchRank : Nat} (plan : Plan rank batchRank 0)
    (indices : Tensor plan.batchShape (Fin 0 → Int)) (batch : Index plan.batchShape)
    (axis : Fin rank) : offset plan indices batch axis = 0 := by
  simp [offset]

/-- The scalar-batch/full-window profile with no index components targets the original
coordinate. -/
theorem full_window_target {rank : Nat} (shape : Shape rank)
    (indices : Tensor (fullWindowPlan shape).batchShape (Fin 0 → Int))
    (batch : Index (fullWindowPlan shape).batchShape) (window : Index shape) :
    target? (fullWindowPlan shape) indices batch window = some window := by
  apply (target_eq_some_iff _ _ _ _ _).mpr
  intro axis
  rw [empty_vector_offset]
  omega

/-- Filter a complete finite position list at one position, retaining its actual mapped value. -/
theorem filterMap_finRange_single {size : Nat} {α : Type} (query : Fin size)
    (value : Fin size → α) :
    (List.finRange size).filterMap (fun position =>
      if position = query then some (value position) else none) = [value query] := by
  have filtered : (List.finRange size).filter (fun position => position = query) = [query] := by
    simp [List.filter_eq]
  have mapped : (List.finRange size).filterMap (fun position =>
      if position = query then some (value position) else none) =
      ((List.finRange size).filter (fun position => position = query)).map value := by
    induction List.finRange size with
    | nil => rfl
    | cons head tail ih =>
      by_cases hit : head = query <;> simp [hit, ih]
  rw [mapped, filtered]
  rfl

end TensorRewrite.Theory.OrderedScatter
