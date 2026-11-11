module

public import TensorRewrite.Theory.BroadcastWindowGeometry
public import TensorRewrite.Pilot.Reshape
public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.Indexing

/-! Actual logical reshape and signed-axis Broadcast target, with derived shape obligations. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.BroadcastWindow

open Pilot

/-- Compact input coordinates expand by inserting zeros exactly at removed singleton axes. -/
def expandIndex : (plan : Plan) → Index (compactPlan plan).outputShape →
    Index (windowPlan plan).inputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep _ _ tail, index =>
    Fin.cases (index ⟨0, Nat.zero_lt_succ _⟩) (expandIndex tail (fun axis => index axis.succ))
  | .expand _ _ tail, index =>
    Fin.cases ⟨0, by change 0 < 1; decide⟩ (expandIndex tail index)

/-- Project output coordinates onto the retained original axes. -/
def compactIndex : (plan : Plan) → Index (windowPlan plan).outputShape →
    Index (compactPlan plan).outputShape
  | .scalar, _ => fun axis => Fin.elim0 axis
  | .keep axis pointwise tail, output =>
    Fin.cases (Fin.cast (ConvolutionPointwise.output_extent_eq axis pointwise)
      (output ⟨0, Nat.zero_lt_succ _⟩)) (compactIndex tail (fun axis => output axis.succ))
  | .expand _ _ tail, output => compactIndex tail (fun axis => output axis.succ)

/-- The unique original input coordinate represented by each output coordinate. -/
def sourceIndex (plan : Plan) (output : Index (windowPlan plan).outputShape) :
    Index (windowPlan plan).inputShape := expandIndex plan (compactIndex plan output)

/-- The actual output-axis position for each retained compact input dimension. -/
def axesMap : (plan : Plan) → Fin (compactPlan plan).outputRank → Fin plan.rank
  | .scalar => Fin.elim0
  | .keep _ _ tail => Fin.cases ⟨0, Nat.zero_lt_succ _⟩ (fun axis => (axesMap tail axis).succ)
  | .expand _ _ tail => fun axis => (axesMap tail axis).succ

/-- Signed Broadcast attributes are constructed from the retained axis positions. -/
def broadcastAxes (plan : Plan) :
    IndexMaps.BroadcastAxes (compactPlan plan).outputRank plan.rank where
  values := Vector.ofFn (fun axis => ((axesMap plan axis).val : Int))
  valid axis := by
    simp only [Fin.getElem_fin, Vector.getElem_ofFn]
    have bound := (axesMap plan axis).isLt
    omega

/-- The constructed signed attributes decode to their original bounded retained axes. -/
theorem axes_decode (plan : Plan) (axis : Fin (compactPlan plan).outputRank) :
    (broadcastAxes plan).decode axis = axesMap plan axis := by
  apply Fin.ext
  simp [IndexMaps.BroadcastAxes.decode, broadcastAxes, Fin.getElem_fin]

/-- Each retained dimension has the exact Broadcast output extent at its constructed axis. -/
theorem axes_extent (plan : Plan) (axis : Fin (compactPlan plan).outputRank) :
    (compactPlan plan).outputShape axis = (windowPlan plan).outputShape (axesMap plan axis) := by
  induction plan with
  | scalar => exact Fin.elim0 axis
  | keep window pointwise tail ih =>
    exact Fin.cases (ConvolutionPointwise.output_extent_eq window pointwise).symm
      (fun axis => ih axis) axis
  | expand expansion covers tail ih => exact ih axis

/-- Removing singleton input axes preserves the actual element count, including empty shapes. -/
theorem compact_count (plan : Plan) :
    LinearIndex.elementCount (windowPlan plan).inputShape =
      LinearIndex.elementCount (compactPlan plan).outputShape := by
  induction plan with
  | scalar => rfl
  | keep axis pointwise tail ih =>
    change axis.inputExtent * LinearIndex.elementCount (windowPlan tail).inputShape =
      axis.inputExtent * LinearIndex.elementCount (compactPlan tail).outputShape
    rw [ih]
  | expand expansion covers tail ih =>
    change 1 * LinearIndex.elementCount (windowPlan tail).inputShape =
      LinearIndex.elementCount (compactPlan tail).outputShape
    rw [Nat.one_mul, ih]

/-- Remove unit axes by logical reshape, then apply the constructed signed-axis Broadcast. -/
def sequence {α : Type} (plan : Plan) (input : Tensor (windowPlan plan).inputShape α) :
    Tensor (windowPlan plan).outputShape α :=
  Tensor.reindex (IndexMaps.broadcastIndex (broadcastAxes plan) (fun axis => by
    rw [axes_decode]
    exact axes_extent plan axis))
    (Reshape.reshapeTensor input (compactPlan plan).outputShape (compact_count plan))

end TensorRewrite.Theory.BroadcastWindow
