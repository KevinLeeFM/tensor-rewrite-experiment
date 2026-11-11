module

public import TensorRewrite.Theory.ScatterLayoutLemmas

/-! Derived ordered Scatter laws for actual interleaved tensors and inserted window dimensions. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterLayout

open Pilot

/-- The actual compact/interleaved Scatter equals the full-rank Scatter with its derived update
adapter. The statement preserves the complete whole-state tensor, not selected coordinates. -/
theorem scatter_eq_ordered {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan operation base indices updates =
      OrderedScatter.scatter plan.toOrdered operation base indices (adaptUpdates plan updates) := by
  unfold scatter OrderedScatter.scatter
  rw [entries_eq_ordered]

/-- Actual event multiplicity is batch count times compact window count, even with inserted
axes or zero update dimensions. -/
theorem entries_length {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    (entries plan indices updates).length =
      LinearIndex.elementCount plan.updateAxes.outputShape *
        LinearIndex.elementCount (ReductionFiber.shape plan.updateAxes) := by
  rw [entries_eq_ordered, OrderedScatter.entries_length]
  exact congrArg (LinearIndex.elementCount plan.updateAxes.outputShape * ·)
    (elementCount_full plan.windows)

/-- An empty actual batch or compact update window returns the original whole state. -/
theorem scatter_empty {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (empty : LinearIndex.elementCount plan.updateAxes.outputShape = 0 ∨
      LinearIndex.elementCount (ReductionFiber.shape plan.updateAxes) = 0)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan operation base indices updates = base := by
  rw [scatter_eq_ordered]
  apply OrderedScatter.scatter_empty plan.toOrdered _ operation base indices
    (adaptUpdates plan updates)
  rcases empty with batch | window
  · exact Or.inl batch
  · exact Or.inr ((elementCount_full plan.windows).trans window)

/-- A reducer homomorphism transports actual raw update values, retaining batch/window
interleaving, singleton insertion and the exact ordered trace. -/
theorem scatter_map {indexSize : Nat} {α β : Type} (plan : Plan indexSize) (convert : α → β)
    (first : α → α → α) (second : β → β → β)
    (hom : ∀ a b, convert (first a b) = second (convert a) (convert b))
    (base : Tensor plan.operandShape α)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    Tensor.map convert (scatter plan first base indices updates) =
      scatter plan second (Tensor.map convert base) indices (Tensor.map convert updates) := by
  rw [scatter_eq_ordered, scatter_eq_ordered,
    OrderedScatter.scatter_map plan.toOrdered convert first second hom]
  rfl

/-- Associativity transports a base factor through the actual raw-input Scatter. -/
theorem scatter_translate {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (first base : Tensor plan.operandShape α)
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape α) :
    scatter plan operation (Tensor.map₂ operation first base) indices updates =
      Tensor.map₂ operation first (scatter plan operation base indices updates) := by
  rw [scatter_eq_ordered, scatter_eq_ordered]
  exact OrderedScatter.scatter_translate plan.toOrdered operation assoc first base indices _

/-- Both outer Add orientations and distinct word reducer parameter orders admit base-factor
transport for the actual compact/interleaved tensor profile. -/
theorem word_translate_distinct {indexSize width : Nat} (plan : Plan indexSize) (order : Bool)
    (first second : ReducerIndex.ScatterRoles.Parameter) (distinct : first ≠ second)
    (separate base : Tensor plan.operandShape (BitVec width))
    (indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (updates : Tensor plan.updateAxes.inputShape (BitVec width)) :
    OperandOrder.map₂ (· + ·) order separate
        (scatter plan (ReducerIndex.ScatterRoles.combine first second) base indices updates) =
      scatter plan (ReducerIndex.ScatterRoles.combine first second)
        (Tensor.map₂ (· + ·) separate base) indices updates := by
  rw [scatter_eq_ordered, scatter_eq_ordered]
  exact OrderedScatter.word_translate_distinct plan.toOrdered order first second distinct
    separate base indices _

/-- Combining two actual interleaved-input Scatters equals their nested target under assoc/comm.
Both original index/update tensors retain their own ordered contributions. -/
theorem scatter_combine_nested {indexSize : Nat} {α : Type} (plan : Plan indexSize)
    (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (first second : Tensor plan.operandShape α)
    (leftIndices rightIndices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int))
    (leftUpdates rightUpdates : Tensor plan.updateAxes.inputShape α) :
    Tensor.map₂ operation (scatter plan operation first leftIndices leftUpdates)
        (scatter plan operation second rightIndices rightUpdates) =
      scatter plan operation
        (scatter plan operation (Tensor.map₂ operation first second) leftIndices leftUpdates)
        rightIndices rightUpdates :=
  OrderedScatter.run_combine_nested operation assoc comm first second
    (entries plan leftIndices leftUpdates) (entries plan rightIndices rightUpdates)

end TensorRewrite.Theory.ScatterLayout
