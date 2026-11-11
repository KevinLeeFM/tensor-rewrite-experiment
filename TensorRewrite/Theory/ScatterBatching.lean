module

public import TensorRewrite.Theory.ScatterIndicesProof

/-! Paired operand/index batch dimensions for actual raw-input ordered Scatter. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterBatching

open Pilot

/-- Identify actual operand-window dimensions omitted from the compact update window. -/
def insertedAxis : {rank : Nat} → {shape : Shape rank} →
    (embedding : ScatterLayout.WindowEmbedding shape) → Fin embedding.fullRank → Bool
  | _, _, .scalar, axis => Fin.elim0 axis
  | _, _, .insert tail, axis => Fin.cases true (insertedAxis tail) axis
  | _, _, .keep _ tail, axis => Fin.cases false (insertedAxis tail) axis

/-- Recover the actual raw index-tensor axis corresponding to a retained batch axis. -/
def rawBatchAxis : {components batchRank : Nat} → {shape : Shape batchRank} →
    (layout : IndexVector.Layout components shape) → Fin batchRank → Fin layout.rawRank
  | _, _, _, .implicit _, axis => axis
  | _, _, _, .here _ _, axis => axis.succ
  | _, _, _, .batch _ tail, axis =>
    Fin.cases ⟨0, Nat.zero_lt_succ _⟩ (fun axis => (rawBatchAxis tail axis).succ) axis

/-- Checked pairing of operand and index-batch dimensions. Pair-array order may be arbitrary;
both maps are injective, extents agree, and operand batch axes are inserted and not indexed. -/
structure Plan {components : Nat} (scatter : ScatterLayout.Plan components) (pairs : Nat) where
  operandAxes : IndexMaps.BroadcastAxes pairs scatter.windows.fullRank
  indexBatchAxes : IndexMaps.BroadcastAxes pairs scatter.updateAxes.outputRank
  operand_injective : Function.Injective operandAxes.decode
  index_injective : Function.Injective indexBatchAxes.decode
  extents : ∀ pair, scatter.operandShape (operandAxes.decode pair) =
    scatter.updateAxes.outputShape (indexBatchAxes.decode pair)
  inserted : ∀ pair, insertedAxis scatter.windows (operandAxes.decode pair) = true
  disjoint : ∀ component pair, scatter.indexAxes.decode component ≠ operandAxes.decode pair

/-- Search the actual operand pairing array without sorting, clipping or changing its pairing. -/
def pairAt {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs) (axis : Fin scatter.windows.fullRank) : Option (Fin pairs) :=
  (List.finRange pairs).find? (fun pair => plan.operandAxes.decode pair = axis)

/-- Actual signed position: paired axes use their bounded index-batch coordinate directly;
all other axes use the original vector offset plus the actual window coordinate. -/
def position {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape)
    (axis : Fin scatter.windows.fullRank) : Int :=
  match pairAt plan axis with
  | some pair => (batch (plan.indexBatchAxes.decode pair)).val
  | none => OrderedScatter.offset scatter.toOrdered indices batch axis + (window axis).val

/-- Check every actual signed operand coordinate, retaining the original element-drop policy. -/
def target? {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int))
    (batch : Index scatter.updateAxes.outputShape) (window : Index scatter.windows.fullShape) :
    Option (Index scatter.operandShape) :=
  LatticeIndex.assemble? fun axis => LatticeIndex.decode? (scatter.operandShape axis) 1 (by decide)
    (position plan indices batch window axis)

/-- An actual signed identity index-axis vector for the canonical full-rank representation. -/
def identityAxes (rank : Nat) : IndexMaps.BroadcastAxes rank rank where
  values := Vector.ofFn (fun axis : Fin rank => (axis.val : Int))
  valid := by intro axis; simp

/-- Represent the derived complete operand-axis starts in the existing ordered evaluator. -/
abbrev canonicalPlan {components : Nat} (scatter : ScatterLayout.Plan components) :
    OrderedScatter.Plan scatter.windows.fullRank scatter.updateAxes.outputRank
      scatter.windows.fullRank where
  operandShape := scatter.operandShape
  batchShape := scatter.updateAxes.outputShape
  windowShape := scatter.windows.fullShape
  indexAxes := identityAxes scatter.windows.fullRank
  injective := by
    intro first second same
    apply Fin.ext
    have equal := congrArg Fin.val same
    simpa [IndexMaps.BroadcastAxes.decode, identityAxes] using equal

/-- Derive every canonical start from original vector values or the selected bounded batch
coordinate. Omitted original index axes retain their actual zero start. -/
def canonicalIndices {components pairs : Nat} {scatter : ScatterLayout.Plan components}
    (plan : Plan scatter pairs)
    (indices : Tensor scatter.updateAxes.outputShape (Fin components → Int)) :
    Tensor scatter.updateAxes.outputShape (Fin scatter.windows.fullRank → Int) := fun batch axis =>
  match pairAt plan axis with
  | some pair => (batch (plan.indexBatchAxes.decode pair)).val
  | none => OrderedScatter.offset scatter.toOrdered indices batch axis

/-- Derive original ordered events from actual raw index/update tensors and the paired batch
coordinates, rather than treating every batch as updating the same operand slice. -/
def entries {components pairs : Nat} {α : Type} (scatter : ScatterLayout.Plan components)
    (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    List (OrderedScatter.Entry scatter.operandShape α) :=
  (OrderedCoordinates.enumerate scatter.updateAxes.outputShape).flatMap fun batch =>
    (OrderedCoordinates.enumerate (ReductionFiber.shape scatter.updateAxes)).map fun window =>
      ⟨target? plan (IndexVector.read layout indices) batch (scatter.windows.expandIndex window),
        updates (ReductionFiber.mergeIndex scatter.updateAxes batch window)⟩

/-- Whole-state ordered Scatter with actual paired operand/index batching dimensions. -/
def run {components pairs : Nat} {α : Type} (scatter : ScatterLayout.Plan components)
    (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor scatter.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    Tensor scatter.operandShape α := OrderedScatter.run operation base (entries scatter plan layout
      indices updates)

end TensorRewrite.Theory.ScatterBatching
