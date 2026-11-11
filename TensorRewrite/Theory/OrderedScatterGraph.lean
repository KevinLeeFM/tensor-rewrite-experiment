module

public import TensorRewrite.Theory.OrderedScatterTransport

/-! Whole-state empty/Map laws and valid scalar/word translation for the actual Scatter graph. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- A reducer homomorphism maps actual base/update values and the derived original event order. -/
theorem scatter_map {rank batchRank indexSize : Nat} {α β : Type}
    (plan : Plan rank batchRank indexSize) (convert : α → β)
    (first : α → α → α) (second : β → β → β)
    (hom : ∀ a b, convert (first a b) = second (convert a) (convert b))
    (base : Tensor plan.operandShape α) (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    Tensor.map convert (scatter plan first base indices updates) =
      scatter plan second (Tensor.map convert base) indices
        (fun batch => Tensor.map convert (updates batch)) := by
  change Tensor.map convert (run first base (entries plan indices updates)) = _
  rw [run_map convert first second hom]
  exact congrArg (run second (Tensor.map convert base))
    (entries_map plan convert indices updates).symm

/-- Empty events preserve the outer tuple of tensors even for a coupled heterogeneous reducer. -/
theorem empty_components {rank batchRank indexSize count : Nat} (α : Fin count → Type)
    (plan : Plan rank batchRank indexSize)
    (empty : LinearIndex.elementCount plan.batchShape = 0 ∨
      LinearIndex.elementCount plan.windowShape = 0)
    (operation : ((component : Fin count) → α component) →
      ((component : Fin count) → α component) → ((component : Fin count) → α component))
    (bases : (component : Fin count) → Tensor plan.operandShape (α component))
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape ((component : Fin count) →
      α component))) :
    (fun component index => scatter plan operation (fun index component => bases component index)
      indices updates index component) = bases := by
  rw [scatter_empty plan empty]

/-- Moving an actual associative reducer's base translation through Scatter keeps its
event trace. -/
theorem scatter_translate {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize) (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (first base : Tensor plan.operandShape α)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    scatter plan operation (Tensor.map₂ operation first base) indices updates =
      Tensor.map₂ operation first (scatter plan operation base indices updates) :=
  run_translate operation assoc first base (entries plan indices updates)

/-- Both Add orientations and both distinct reducer parameter orders preserve actual
word Scatter. -/
theorem word_translate_distinct {rank batchRank indexSize width : Nat}
    (plan : Plan rank batchRank indexSize) (order : Bool)
    (first second : ReducerIndex.ScatterRoles.Parameter) (distinct : first ≠ second)
    (separate base : Tensor plan.operandShape (BitVec width))
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape (BitVec width))) :
    OperandOrder.map₂ (· + ·) order separate
      (scatter plan (ReducerIndex.ScatterRoles.combine first second) base indices updates) =
    scatter plan (ReducerIndex.ScatterRoles.combine first second)
      (Tensor.map₂ (· + ·) separate base) indices updates := by
  rw [distinct_word_operation first second distinct]
  rw [OperandOrder.map₂_eq (· + ·) BitVec.add_comm]
  exact (scatter_translate plan (· + ·) BitVec.add_assoc separate base indices updates).symm

end TensorRewrite.Theory.OrderedScatter
