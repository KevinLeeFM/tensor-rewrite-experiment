module

public import TensorRewrite.Theory.BroadcastWindowTarget
public import TensorRewrite.Pilot.LinearIndexLemmas

/-! Coordinate and order proofs for the real reshape-plus-Broadcast target. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- Strictly ordered retained axes give Broadcast attributes without duplicates. -/
theorem axesMap_strictMono (plan : Plan) : StrictMono (axesMap plan) := by
  induction plan with
  | scalar => intro first; exact Fin.elim0 first
  | keep window pointwise tail ih =>
    intro first second less
    revert second
    refine Fin.cases ?_ (fun first => ?_) first
    · intro second
      refine Fin.cases (fun less => ?_) (fun second less => ?_) second
      · exact False.elim ((lt_irrefl _) less)
      · change 0 < (axesMap tail second).val + 1
        omega
    · intro second
      refine Fin.cases (fun less => ?_) (fun second less => ?_) second
      · have impossible : first.val + 1 < 0 := less
        omega
      · have inner : first < second := by
          change first.val < second.val
          have bound : first.val + 1 < second.val + 1 := less
          omega
        have ordered := ih inner
        change (axesMap tail first).val + 1 < (axesMap tail second).val + 1
        exact Nat.add_lt_add_right ordered 1
  | expand expansion covers tail ih =>
    intro first second less
    have ordered := ih less
    change (axesMap tail first).val + 1 < (axesMap tail second).val + 1
    exact Nat.add_lt_add_right ordered 1

/-- Projecting compact coordinates reads exactly the retained output axes. -/
theorem compact_index_value (plan : Plan) (output : Index (windowPlan plan).outputShape)
    (axis : Fin (compactPlan plan).outputRank) :
    (compactIndex plan output axis).val = (output (axesMap plan axis)).val := by
  induction plan with
  | scalar => exact Fin.elim0 axis
  | keep window pointwise tail ih =>
    exact Fin.cases rfl (fun axis => ih (fun axis => output axis.succ) axis) axis
  | expand expansion covers tail ih => exact ih (fun axis => output axis.succ) axis

/-- The existing signed-axis Broadcast index map is the derived retained-coordinate projection. -/
theorem broadcast_index (plan : Plan) (output : Index (windowPlan plan).outputShape) :
    IndexMaps.broadcastIndex (broadcastAxes plan) (fun axis => by
      rw [axes_decode]
      exact axes_extent plan axis) output = compactIndex plan output := by
  funext axis
  apply Fin.ext
  exact (congrArg (fun position => (output position).val) (axes_decode plan axis)).trans
    (compact_index_value plan output axis).symm

/-- Inserting singleton zero coordinates preserves the actual logical linear position. -/
theorem linearize_expand (plan : Plan) (index : Index (compactPlan plan).outputShape) :
    (LinearIndex.linearize (windowPlan plan).inputShape (expandIndex plan index)).val =
      (LinearIndex.linearize (compactPlan plan).outputShape index).val := by
  induction plan with
  | scalar => rfl
  | keep window pointwise tail ih =>
    change (index ⟨0, Nat.zero_lt_succ _⟩).val *
      LinearIndex.elementCount (windowPlan tail).inputShape +
      (LinearIndex.linearize (windowPlan tail).inputShape
        (expandIndex tail (fun axis => index axis.succ))).val =
      (index ⟨0, Nat.zero_lt_succ _⟩).val *
      LinearIndex.elementCount (compactPlan tail).outputShape +
      (LinearIndex.linearize (compactPlan tail).outputShape (fun axis => index axis.succ)).val
    exact congrArg₂ (fun count position =>
      (index ⟨0, Nat.zero_lt_succ _⟩).val * count + position) (compact_count tail) (ih _)
  | expand expansion covers tail ih =>
    change 0 * LinearIndex.elementCount (windowPlan tail).inputShape +
      (LinearIndex.linearize (windowPlan tail).inputShape (expandIndex tail index)).val = _
    rw [Nat.zero_mul, Nat.zero_add]
    exact ih index

/-- The existing logical reshape index map equals insertion of singleton coordinates. -/
theorem reshape_index (plan : Plan) (index : Index (compactPlan plan).outputShape) :
    Reshape.reshapeIndex (windowPlan plan).inputShape (compactPlan plan).outputShape
      (compact_count plan) index = expandIndex plan index := by
  unfold Reshape.reshapeIndex
  rw [← LinearIndex.delinearize_linearize (windowPlan plan).inputShape (expandIndex plan index)]
  congr 1
  apply Fin.ext
  exact (linearize_expand plan index).symm

/-- The constructed sequence reads the original coordinate derived from window geometry. -/
theorem sequence_value {α : Type} (plan : Plan) (input : Tensor (windowPlan plan).inputShape α)
    (output : Index (windowPlan plan).outputShape) :
    sequence plan input output = input (sourceIndex plan output) := by
  unfold sequence Tensor.reindex Reshape.reshapeTensor
  rw [broadcast_index, reshape_index]
  rfl

end TensorRewrite.Theory.BroadcastWindow
