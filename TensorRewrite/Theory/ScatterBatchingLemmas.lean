module

public import TensorRewrite.Theory.ScatterBatching

/-! Batching-axis lookup, actual raw coordinates and canonical bounded target equivalence. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterBatching

open Pilot

/-- Every actually inserted operand-window dimension has singleton extent. -/
theorem inserted_extent {rank : Nat} {shape : Shape rank}
    (embedding : ScatterLayout.WindowEmbedding shape) (axis : Fin embedding.fullRank)
    (selected : insertedAxis embedding axis = true) : embedding.fullShape axis = 1 := by
  induction embedding with
  | scalar => exact Fin.elim0 axis
  | insert tail ih =>
    revert selected
    exact Fin.cases (fun _ => rfl) (fun axis selected => ih axis selected) axis
  | keep extent tail ih =>
    revert selected
    exact Fin.cases (fun selected => Bool.noConfusion selected)
      (fun axis selected => ih axis selected) axis

/-- A retained raw index-batch axis has exactly the corresponding actual batch extent. -/
theorem rawBatchAxis_extent {components batchRank : Nat} {shape : Shape batchRank}
    (layout : IndexVector.Layout components shape) (axis : Fin batchRank) :
    layout.rawShape (rawBatchAxis layout axis) = shape axis := by
  induction layout with
  | implicit => rfl
  | here => rfl
  | batch extent tail ih => exact Fin.cases rfl (fun axis => ih axis) axis

/-- The actual raw coordinate reader retains the selected batch coordinate at its derived raw
axis, independent of vector-axis position or explicit/implicit representation. -/
theorem rawIndex_batch_value {components batchRank : Nat} {shape : Shape batchRank}
    (layout : IndexVector.Layout components shape) (batch : Index shape)
    (component : Fin components) (axis : Fin batchRank) :
    (layout.rawIndex batch component (rawBatchAxis layout axis)).val = (batch axis).val := by
  induction layout with
  | implicit => rfl
  | here => rfl
  | batch extent tail ih =>
    exact Fin.cases rfl (fun axis => ih (fun axis => batch axis.succ) component axis) axis

/-- Searching the injective operand batch-axis array recovers the actual paired position. -/
theorem pairAt_mapped {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs) (pair : Fin pairs) :
    pairAt plan (plan.operandAxes.decode pair) = some pair := by
  cases found : pairAt plan (plan.operandAxes.decode pair) with
  | none =>
    have absent := List.find?_eq_none.mp found
    have impossible := absent pair (List.mem_finRange pair)
    simp at impossible
  | some other =>
    have equal : plan.operandAxes.decode other = plan.operandAxes.decode pair := by
      simpa only [decide_eq_true_eq] using List.find?_some found
    have same := plan.operand_injective equal
    subst other
    rfl

/-- An operand dimension absent from the actual batching array has no batch-coordinate override. -/
theorem pairAt_unmapped {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs) (axis : Fin scatter.windows.fullRank)
    (absent : ∀ pair, plan.operandAxes.decode pair ≠ axis) : pairAt plan axis = none := by
  apply List.find?_eq_none.mpr
  intro pair _
  simpa only [decide_eq_true_eq] using absent pair

/-- The original window coordinate at a paired operand batch axis is forced to zero by actual
singleton insertion, rather than by an assumed target-coordinate equality. -/
theorem window_paired_zero {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs) (window : Index scatter.windows.fullShape) (pair : Fin pairs) :
    (window (plan.operandAxes.decode pair)).val = 0 := by
  have singleton := inserted_extent scatter.windows _ (plan.inserted pair)
  have bound := (window (plan.operandAxes.decode pair)).isLt
  omega

/-- A paired operand batch coordinate is already in bounds by the actual extent equality. -/
theorem batch_coordinate_bound {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs) (batch : Index scatter.updateAxes.outputShape) (pair : Fin pairs) :
    (batch (plan.indexBatchAxes.decode pair)).val <
      scatter.operandShape (plan.operandAxes.decode pair) := by
  rw [plan.extents]
  exact (batch (plan.indexBatchAxes.decode pair)).isLt

/-- The actual generated signed identity-axis vector decodes to the original operand axis. -/
theorem identityAxes_decode {rank : Nat} (axis : Fin rank) :
    (identityAxes rank).decode axis = axis := by
  apply Fin.ext
  simp [identityAxes, IndexMaps.BroadcastAxes.decode]

/-- The original evaluator reads every derived canonical start at its exact operand axis. -/
theorem canonical_offset {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (axis : Fin scatter.windows.fullRank) :
    OrderedScatter.offset (canonicalPlan scatter) (canonicalIndices plan indices) batch axis =
      canonicalIndices plan indices batch axis := by
  have mapped := OrderedScatter.offset_mapped (canonicalPlan scatter)
    (canonicalIndices plan indices) batch axis
  simpa only [identityAxes_decode] using mapped

/-- Derived canonical start plus the original singleton/nonbatch window coordinate equals the
independently defined actual paired-batch position on every axis. -/
theorem canonical_position {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape)
    (axis : Fin scatter.windows.fullRank) :
    canonicalIndices plan indices batch axis + (window axis).val =
      position plan indices batch window axis := by
  cases found : pairAt plan axis with
  | none => simp only [canonicalIndices, position, found]
  | some pair =>
    have equal : plan.operandAxes.decode pair = axis := by
      simpa only [decide_eq_true_eq] using List.find?_some found
    have zero := window_paired_zero plan window pair
    rw [equal] at zero
    simp only [canonicalIndices, position, found, zero, Int.natCast_zero, add_zero]

/-- Actual batching targets equal the existing evaluator's targets for derived canonical starts,
including failure on any invalid nonbatch dimension. -/
theorem target_eq_canonical {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape) :
    target? plan indices batch window =
      OrderedScatter.target? (canonicalPlan scatter) (canonicalIndices plan indices)
        batch window := by
  unfold target? OrderedScatter.target?
  apply congrArg LatticeIndex.assemble?
  funext axis
  rw [canonical_offset, canonical_position]

/-- A successful target uses exactly the independently derived signed coordinate on each axis. -/
theorem target_eq_some_iff {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape)
    (target : Index scatter.operandShape) :
    target? plan indices batch window = some target ↔
      ∀ axis, position plan indices batch window axis = (target axis).val := by
  rw [target_eq_canonical, OrderedScatter.target_eq_some_iff]
  simp only [canonical_offset, canonical_position]

/-- With no paired dimensions, actual target construction recovers the original unbatched
sampler on every axis, including arbitrary empty ranks/extents. -/
theorem target_no_pairs {components : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter 0)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape) :
    target? plan indices batch window = OrderedScatter.target? scatter.toOrdered indices batch
      window := by
  simp only [target?, position, pairAt, List.finRange_zero, List.find?_nil]
  rfl

/-- Every successful actual target retains the selected index-batch coordinate at each paired
operand axis. Other out-of-bounds dimensions may still drop the whole event. -/
theorem target_batch_coordinate {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape)
    (target : Index scatter.operandShape)
    (sampled : target? plan indices batch window = some target)
    (pair : Fin pairs) :
    (target (plan.operandAxes.decode pair)).val =
      (batch (plan.indexBatchAxes.decode pair)).val := by
  have coordinate := (target_eq_some_iff plan indices batch window target).mp sampled
    (plan.operandAxes.decode pair)
  simp only [position, pairAt_mapped] at coordinate
  omega

end TensorRewrite.Theory.ScatterBatching
