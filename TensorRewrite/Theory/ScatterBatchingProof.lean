module

public import TensorRewrite.Theory.ScatterBatchingLemmas

/-! Exact raw-input batched Scatter state, reencoding and algebraic rewrite consequences. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterBatching

open Pilot

/-- Actual paired-batch events equal the canonical evaluator's events for independently derived
starts and raw update adaptation, including payloads, dropped targets, duplicates and order. -/
theorem entries_eq_canonical {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    entries scatter plan layout indices updates =
      OrderedScatter.entries (canonicalPlan scatter)
        (canonicalIndices plan (IndexVector.read layout indices))
        (ScatterLayout.adaptUpdates scatter updates) := by
  rw [ScatterConcat.entries_coordinates, ScatterLayout.enumerate_expand]
  unfold entries
  apply List.flatMap_congr
  intro batch _
  rw [List.map_map]
  apply List.map_congr_left
  intro window _
  change (⟨_, _⟩ : OrderedScatter.Entry scatter.operandShape α) = ⟨_, _⟩
  rw [ScatterLayout.adapt_expand, target_eq_canonical]

/-- The full paired-batch state equals the old evaluator with actual derived canonical starts.
No target-coordinate, tensor equality or scalar algebra premise is postulated. -/
theorem run_eq_canonical {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor scatter.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    run scatter plan layout operation base indices updates =
      OrderedScatter.scatter (canonicalPlan scatter) operation base
        (canonicalIndices plan (IndexVector.read layout indices))
        (ScatterLayout.adaptUpdates scatter updates) :=
  congrArg (OrderedScatter.run operation base)
    (entries_eq_canonical scatter plan layout indices updates)

/-- Actual paired-batch events have the original batch times compact-window multiplicity. -/
theorem entries_length {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    (entries scatter plan layout indices updates).length =
      LinearIndex.elementCount scatter.updateAxes.outputShape *
        LinearIndex.elementCount (ReductionFiber.shape scatter.updateAxes) := by
  rw [entries_eq_canonical, OrderedScatter.entries_length]
  exact congrArg (LinearIndex.elementCount scatter.updateAxes.outputShape * ·)
    (ScatterLayout.elementCount_full scatter.windows)

/-- Empty actual batch or compact-window dimensions preserve the entire original state even
when batch coordinates otherwise select different operand slices. -/
theorem run_empty {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (empty : LinearIndex.elementCount scatter.updateAxes.outputShape = 0 ∨
      LinearIndex.elementCount (ReductionFiber.shape scatter.updateAxes) = 0)
    (operation : α → α → α) (base : Tensor scatter.operandShape α)
    (indices : Tensor layout.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    run scatter plan layout operation base indices updates = base := by
  have count := entries_length scatter plan layout indices updates
  have absent : (entries scatter plan layout indices updates).length = 0 := by
    rcases empty with batch | window <;> simp_all
  have noEvents := List.length_eq_zero_iff.mp absent
  simp only [run, noEvents, OrderedScatter.run_empty]

/-- Moving/materializing the actual index vector axis preserves paired operand/index batching,
all original update values and the complete whole-state result under any reducer. -/
theorem run_relayout_indices {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (source target : IndexVector.Layout components scatter.updateAxes.outputShape)
    (operation : α → α → α) (base : Tensor scatter.operandShape α)
    (indices : Tensor source.rawShape Int) (updates : Tensor scatter.updateAxes.inputShape α) :
    run scatter plan target operation base (IndexVector.relayout source target indices) updates =
      run scatter plan source operation base indices updates := by
  rw [run_eq_canonical, run_eq_canonical, IndexVector.read_relayout]

/-- All-width word Add base translation covers both actual reducer role orders and both outer
Add orientations under the paired-batch coordinate and raw tensor contracts. -/
theorem word_translate_distinct {components pairs width : Nat}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape) (order : Bool)
    (first second : ReducerIndex.ScatterRoles.Parameter) (distinct : first ≠ second)
    (separate base : Tensor scatter.operandShape (BitVec width))
    (indices : Tensor layout.rawShape Int)
    (updates : Tensor scatter.updateAxes.inputShape (BitVec width)) :
    OperandOrder.map₂ (· + ·) order separate
        (run scatter plan layout (ReducerIndex.ScatterRoles.combine first second) base
          indices updates) =
      run scatter plan layout (ReducerIndex.ScatterRoles.combine first second)
        (Tensor.map₂ (· + ·) separate base) indices updates := by
  rw [run_eq_canonical, run_eq_canonical]
  exact OrderedScatter.word_translate_distinct (canonicalPlan scatter) order first second distinct
    separate base _ _

/-- Assoc/comm combines two actual paired-batch results into their original nested Scatter
traces, allowing different raw vector-axis representations on the two inputs. -/
theorem run_combine_nested {components pairs : Nat} {α : Type}
    (scatter : ScatterLayout.Plan components) (plan : Plan scatter pairs)
    (leftLayout rightLayout : IndexVector.Layout components scatter.updateAxes.outputShape)
    (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (first second : Tensor scatter.operandShape α)
    (leftIndices : Tensor leftLayout.rawShape Int) (rightIndices : Tensor rightLayout.rawShape Int)
    (leftUpdates rightUpdates : Tensor scatter.updateAxes.inputShape α) :
    Tensor.map₂ operation (run scatter plan leftLayout operation first leftIndices leftUpdates)
        (run scatter plan rightLayout operation second rightIndices rightUpdates) =
      run scatter plan rightLayout operation
        (run scatter plan leftLayout operation (Tensor.map₂ operation first second)
          leftIndices leftUpdates) rightIndices rightUpdates :=
  OrderedScatter.run_combine_nested operation assoc comm first second
    (entries scatter plan leftLayout leftIndices leftUpdates)
    (entries scatter plan rightLayout rightIndices rightUpdates)

end TensorRewrite.Theory.ScatterBatching
