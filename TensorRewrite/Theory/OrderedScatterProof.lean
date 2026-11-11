module

public import TensorRewrite.Theory.OrderedScatterFullWindow

/-! Empty/full-window and associative-commutative fusion laws for actual ordered Scatter events. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- Empty traces return the original whole state without reducer or component assumptions. -/
theorem run_empty {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (base : Tensor shape α) : run operation base [] = base := rfl

/-- No update event means the entire declared Scatter returns its original tensor. -/
theorem scatter_empty {rank batchRank indexSize : Nat} {α : Type}
    (plan : Plan rank batchRank indexSize)
    (empty : LinearIndex.elementCount plan.batchShape = 0 ∨
      LinearIndex.elementCount plan.windowShape = 0)
    (operation : α → α → α) (base : Tensor plan.operandShape α)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    scatter plan operation base indices updates = base := by
  rcases empty with batch | window
  · rw [scatter, entries_empty_batch plan batch, run_empty]
  · rw [scatter, entries_empty_window plan window, run_empty]

/-- An empty index vector, scalar batch and full window equal the actual pointwise binary Map. -/
theorem full_window_map {rank : Nat} {α : Type} (shape : Shape rank) (operation : α → α → α)
    (base : Tensor shape α) (indices : Tensor (fullWindowPlan shape).batchShape (Fin 0 → Int))
    (updates : Tensor (fullWindowPlan shape).batchShape (Tensor shape α)) :
    scatter (fullWindowPlan shape) operation base indices updates =
      Tensor.map₂ operation base (updates (fun axis => Fin.elim0 axis)) := by
  change run operation base (entries (fullWindowPlan shape) indices updates) = _
  funext index
  exact (run_at operation base (entries (fullWindowPlan shape) indices updates) index).trans
    (congrArg (fun values : List α => values.foldl operation (base index))
      (values_full_window shape indices updates index))

/-- Translating the base through one ordered Scatter requires actual reducer associativity. -/
theorem run_translate {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (first base : Tensor shape α) (events : List (Entry shape α)) :
    run operation (Tensor.map₂ operation first base) events =
      Tensor.map₂ operation first (run operation base events) := by
  funext index
  change run operation (Tensor.map₂ operation first base) events index =
    operation (first index) (run operation base events index)
  rw [run_at, run_at]
  exact foldl_translate operation assoc _ _ _

/-- Two original scatters combine into the actual concatenated trace under assoc/comm laws. -/
theorem run_combine {rank : Nat} {shape : Shape rank} {α : Type} (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (first second : Tensor shape α) (left right : List (Entry shape α)) :
    Tensor.map₂ operation (run operation first left) (run operation second right) =
      run operation (Tensor.map₂ operation first second) (left ++ right) := by
  funext index
  change operation (run operation first left index) (run operation second right index) = _
  rw [run_at, run_at, run_at, values_append]
  exact foldl_combine operation assoc comm _ _ _ _

/-- The actual nested target follows from trace composition, without assuming the graph law. -/
theorem run_combine_nested {rank : Nat} {shape : Shape rank} {α : Type}
    (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (first second : Tensor shape α) (left right : List (Entry shape α)) :
    Tensor.map₂ operation (run operation first left) (run operation second right) =
      run operation (run operation (Tensor.map₂ operation first second) left) right := by
  rw [run_combine operation assoc comm, run_append]

/-- Modulo-word addition instantiates concatenated fusion even when intermediate values wrap. -/
theorem word_combine {rank width : Nat} {shape : Shape rank}
    (first second : Tensor shape (BitVec width)) (left right : List (Entry shape (BitVec width))) :
    Tensor.map₂ (· + ·) (run (· + ·) first left) (run (· + ·) second right) =
      run (· + ·) (Tensor.map₂ (· + ·) first second) (left ++ right) :=
  run_combine (· + ·) BitVec.add_assoc BitVec.add_comm first second left right

end TensorRewrite.Theory.OrderedScatter
