module

public import TensorRewrite.Theory.ScatterConcat

/-! Derive concatenated Scatter events from bounded input tensor coordinates. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterConcat

open Pilot

/-- Reading the left block of an actual concatenated tensor recovers its original value. -/
theorem concatenate_left {rank first second : Nat} {α : Type} (tail : Shape rank)
    (left : Tensor (batchShape first tail) α) (right : Tensor (batchShape second tail) α)
    (index : Index (batchShape first tail)) :
    concatenate tail left right (leftIndex second tail index) = left index := by
  have before : (index 0).val < first := (index 0).isLt
  unfold concatenate
  have embedded : ((leftIndex second tail index) 0).val < first := before
  rw [dite_eq_left embedded]
  apply congrArg left
  funext axis
  refine Fin.cases ?_ (fun _ => rfl) axis
  exact Fin.ext rfl

/-- Reading the right block subtracts the left extent once and recovers the original value. -/
theorem concatenate_right {rank first second : Nat} {α : Type} (tail : Shape rank)
    (left : Tensor (batchShape first tail) α) (right : Tensor (batchShape second tail) α)
    (index : Index (batchShape second tail)) :
    concatenate tail left right (rightIndex first tail index) = right index := by
  have after : ¬ first + (index 0).val < first := by omega
  unfold concatenate
  have embedded : ¬ ((rightIndex first tail index) 0).val < first := after
  rw [dite_eq_right embedded]
  apply congrArg right
  funext axis
  refine Fin.cases ?_ (fun _ => rfl) axis
  apply Fin.ext
  change first + (index 0).val - first = (index 0).val
  omega

/-- The actual row-major batch enumeration splits into the left and right embedded tensors.
This statement retains order and all zero-extent cases. -/
theorem enumerate_concatenate {rank : Nat} (first second : Nat) (tail : Shape rank) :
    OrderedCoordinates.enumerate (batchShape (first + second) tail) =
      (OrderedCoordinates.enumerate (batchShape first tail)).map (leftIndex second tail) ++
      (OrderedCoordinates.enumerate (batchShape second tail)).map (rightIndex first tail) := by
  rw [OrderedCoordinates.enumerate_uncons, OrderedCoordinates.enumerate_uncons,
    OrderedCoordinates.enumerate_uncons]
  simp only [batchShape, Fin.cases_zero, Fin.cases_succ, List.map_flatMap, List.map_map]
  change (List.finRange (first + second)).flatMap (fun head =>
    (OrderedCoordinates.enumerate tail).map fun rest =>
      (Fin.cases head rest : Index (batchShape (first + second) tail))) = _
  rw [List.flatMap_def, ← List.ofFn_eq_map, List.ofFn_add, List.flatten_append]
  simp only [List.ofFn_eq_map]
  rfl

/-- The original Scatter evaluator enumerates actual bounded coordinates in both tensors. -/
theorem entries_coordinates {rank batchRank indexSize : Nat} {α : Type}
    (plan : OrderedScatter.Plan rank batchRank indexSize)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    OrderedScatter.entries plan indices updates =
      (OrderedCoordinates.enumerate plan.batchShape).flatMap fun batch =>
        (OrderedCoordinates.enumerate plan.windowShape).map fun window =>
          (⟨OrderedScatter.target? plan indices batch window, updates batch window⟩ :
            OrderedScatter.Entry plan.operandShape α) := by
  simp only [OrderedScatter.entries, OrderedCoordinates.enumerate, List.flatMap_map, List.map_map]
  rfl

/-- Equal actual index-vector values give equal bounded targets under the shared geometry;
the equality premise does not postulate an event or tensor graph equivalence. -/
theorem target_rebatch {rank oldBatchRank leftRank rightRank indexSize : Nat}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize)
    (leftShape : Shape leftRank) (rightShape : Shape rightRank)
    (left : Tensor leftShape (Fin indexSize → Int))
    (right : Tensor rightShape (Fin indexSize → Int))
    (leftBatch : Index leftShape) (rightBatch : Index rightShape)
    (same : left leftBatch = right rightBatch) (window : Index geometry.windowShape) :
    OrderedScatter.target? (rebatch geometry leftShape) left leftBatch window =
      OrderedScatter.target? (rebatch geometry rightShape) right rightBatch window := by
  simp only [OrderedScatter.target?, OrderedScatter.offset, rebatch]
  rw [same]

/-- Concatenating actual index and update tensors derives the exact appended event trace.
Targets, dropped entries, duplicates, payload pairing and their order are all preserved. -/
theorem entries_concatenate {rank oldBatchRank tailRank indexSize first second : Nat} {α : Type}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (tail : Shape tailRank)
    (leftIndices : Tensor (batchShape first tail) (Fin indexSize → Int))
    (rightIndices : Tensor (batchShape second tail) (Fin indexSize → Int))
    (leftUpdates : Tensor (batchShape first tail) (Tensor geometry.windowShape α))
    (rightUpdates : Tensor (batchShape second tail) (Tensor geometry.windowShape α)) :
    OrderedScatter.entries (rebatch geometry (batchShape (first + second) tail))
        (concatenate tail leftIndices rightIndices) (concatenate tail leftUpdates rightUpdates) =
      OrderedScatter.entries (rebatch geometry (batchShape first tail)) leftIndices leftUpdates ++
      OrderedScatter.entries (rebatch geometry (batchShape second tail))
        rightIndices rightUpdates := by
  rw [entries_coordinates, entries_coordinates, entries_coordinates]
  change (OrderedCoordinates.enumerate (batchShape (first + second) tail)).flatMap _ = _
  rw [enumerate_concatenate, List.flatMap_append, List.flatMap_map, List.flatMap_map]
  congr 1
  · apply List.flatMap_congr
    intro batch _
    apply List.map_congr_left
    intro window _
    rw [concatenate_left]
    congr 1
    apply target_rebatch
    exact concatenate_left tail leftIndices rightIndices batch
  · apply List.flatMap_congr
    intro batch _
    apply List.map_congr_left
    intro window _
    rw [concatenate_right]
    congr 1
    apply target_rebatch
    exact concatenate_right tail leftIndices rightIndices batch

end TensorRewrite.Theory.ScatterConcat
