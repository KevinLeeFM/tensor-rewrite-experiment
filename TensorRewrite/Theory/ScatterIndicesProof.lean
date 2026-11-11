module

public import TensorRewrite.Theory.ScatterIndices

/-! Exact raw-index reading, vector-axis movement and inherited whole-state Scatter laws. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterIndices

open Pilot

/-- Actual raw index/update coordinate reads equal the existing interleaved-layout event list. -/
theorem entries_eq_layout {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    entries plan layout indices updates =
      ScatterLayout.entries plan (IndexVector.read layout indices) updates := rfl

/-- The complete raw-tensor Scatter equals its derived batch-indexed vector interpretation. -/
theorem scatter_eq_layout {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan layout operation base indices updates =
      ScatterLayout.scatter plan operation base (IndexVector.read layout indices) updates := rfl

/-- Both actual raw tensors derive the original full-rank ordered evaluator, without an assumed
tensor equality, event correspondence or reducer algebra law. -/
theorem scatter_eq_ordered {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan layout operation base indices updates =
      OrderedScatter.scatter plan.toOrdered operation base (IndexVector.read layout indices)
        (ScatterLayout.adaptUpdates plan updates) :=
  ScatterLayout.scatter_eq_ordered plan operation base (IndexVector.read layout indices) updates

/-- Event multiplicity depends on actual batch and compact window counts, not on the number of
raw index elements. In particular an explicit zero-length vector need not mean an empty batch. -/
theorem entries_length {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    (entries plan layout indices updates).length =
      LinearIndex.elementCount plan.updateAxes.outputShape *
        LinearIndex.elementCount (ReductionFiber.shape plan.updateAxes) :=
  ScatterLayout.entries_length plan (IndexVector.read layout indices) updates

/-- Moving the actual vector axis, or materializing/removing an explicit singleton vector axis,
preserves the entire Scatter state and original update order under any reducer. -/
theorem scatter_relayout_indices {components : Nat} {α : Type}
    (plan : ScatterLayout.Plan components)
    (source target : IndexVector.Layout components plan.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor source.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan target operation base (IndexVector.relayout source target indices) updates =
      scatter plan source operation base indices updates := by
  rw [scatter_eq_layout, scatter_eq_layout, IndexVector.read_relayout]

/-- An empty batch or actual compact update window preserves the original whole state. -/
theorem scatter_empty {components : Nat} {α : Type} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape)
    (empty : LinearIndex.elementCount plan.updateAxes.outputShape = 0 ∨
      LinearIndex.elementCount (ReductionFiber.shape plan.updateAxes) = 0)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan layout operation base indices updates = base :=
  ScatterLayout.scatter_empty plan empty operation base (IndexVector.read layout indices) updates

/-- Actual distinct word reducer roles admit base translation with both raw tensor layouts,
all word widths and both outer Add orientations. -/
theorem word_translate_distinct {components width : Nat} (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape) (order : Bool)
    (first second : ReducerIndex.ScatterRoles.Parameter) (distinct : first ≠ second)
    (separate base : Tensor plan.operandShape (BitVec width))
    (indices : Tensor layout.rawShape Int)
    (updates : Tensor plan.updateAxes.inputShape (BitVec width)) :
    OperandOrder.map₂ (· + ·) order separate
        (scatter plan layout (ReducerIndex.ScatterRoles.combine first second)
          base indices updates) =
      scatter plan layout (ReducerIndex.ScatterRoles.combine first second)
        (Tensor.map₂ (· + ·) separate base) indices updates :=
  ScatterLayout.word_translate_distinct plan order first second distinct separate base
    (IndexVector.read layout indices) updates

end TensorRewrite.Theory.ScatterIndices
