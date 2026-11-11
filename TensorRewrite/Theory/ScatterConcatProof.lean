module

public import TensorRewrite.Theory.ScatterConcatLemmas

/-! Whole-state and word-add Scatter graph laws using actual concatenated tensor inputs. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterConcat

open Pilot

/-- A Scatter over concatenated tensors executes the left Scatter and then the right one,
under any whole-state reducer, without associativity, commutativity or unique-target premises. -/
theorem scatter_concatenate {rank oldBatchRank tailRank indexSize first second : Nat} {α : Type}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (tail : Shape tailRank)
    (operation : α → α → α) (base : Tensor geometry.operandShape α)
    (leftIndices : Tensor (batchShape first tail) (Fin indexSize → Int))
    (rightIndices : Tensor (batchShape second tail) (Fin indexSize → Int))
    (leftUpdates : Tensor (batchShape first tail) (Tensor geometry.windowShape α))
    (rightUpdates : Tensor (batchShape second tail) (Tensor geometry.windowShape α)) :
    OrderedScatter.scatter (rebatch geometry (batchShape (first + second) tail)) operation base
        (concatenate tail leftIndices rightIndices) (concatenate tail leftUpdates rightUpdates) =
      OrderedScatter.scatter (rebatch geometry (batchShape second tail)) operation
        (OrderedScatter.scatter (rebatch geometry (batchShape first tail)) operation base
          leftIndices leftUpdates) rightIndices rightUpdates := by
  simp only [OrderedScatter.scatter]
  rw [entries_concatenate, OrderedScatter.run_append]

/-- Two Scatter results combine into one Scatter with actual concatenated index/update tensors
under explicitly supplied associativity and commutativity laws. -/
theorem scatter_combine {rank oldBatchRank tailRank indexSize first second : Nat} {α : Type}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (tail : Shape tailRank)
    (operation : α → α → α)
    (assoc : ∀ a b c, operation (operation a b) c = operation a (operation b c))
    (comm : ∀ a b, operation a b = operation b a)
    (leftBase rightBase : Tensor geometry.operandShape α)
    (leftIndices : Tensor (batchShape first tail) (Fin indexSize → Int))
    (rightIndices : Tensor (batchShape second tail) (Fin indexSize → Int))
    (leftUpdates : Tensor (batchShape first tail) (Tensor geometry.windowShape α))
    (rightUpdates : Tensor (batchShape second tail) (Tensor geometry.windowShape α)) :
    Tensor.map₂ operation
        (OrderedScatter.scatter (rebatch geometry (batchShape first tail)) operation leftBase
          leftIndices leftUpdates)
        (OrderedScatter.scatter (rebatch geometry (batchShape second tail)) operation rightBase
          rightIndices rightUpdates) =
      OrderedScatter.scatter (rebatch geometry (batchShape (first + second) tail)) operation
        (Tensor.map₂ operation leftBase rightBase) (concatenate tail leftIndices rightIndices)
        (concatenate tail leftUpdates rightUpdates) := by
  simp only [OrderedScatter.scatter]
  rw [entries_concatenate]
  exact OrderedScatter.run_combine operation assoc comm _ _ _ _

/-- Arbitrary-width word Add and either distinct reducer parameter order admit tensor-input
Concat fusion. Both source nodes must use the same actual reducer parameter order. -/
theorem word_combine_distinct
    {rank oldBatchRank tailRank indexSize first second width : Nat}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (tail : Shape tailRank)
    (firstRole secondRole : ReducerIndex.ScatterRoles.Parameter)
    (distinct : firstRole ≠ secondRole)
    (leftBase rightBase : Tensor geometry.operandShape (BitVec width))
    (leftIndices : Tensor (batchShape first tail) (Fin indexSize → Int))
    (rightIndices : Tensor (batchShape second tail) (Fin indexSize → Int))
    (leftUpdates : Tensor (batchShape first tail) (Tensor geometry.windowShape (BitVec width)))
    (rightUpdates : Tensor (batchShape second tail) (Tensor geometry.windowShape (BitVec width))) :
    Tensor.map₂ (· + ·)
        (OrderedScatter.scatter (rebatch geometry (batchShape first tail))
          (ReducerIndex.ScatterRoles.combine firstRole secondRole) leftBase leftIndices leftUpdates)
        (OrderedScatter.scatter (rebatch geometry (batchShape second tail))
          (ReducerIndex.ScatterRoles.combine firstRole secondRole) rightBase rightIndices
          rightUpdates) =
      OrderedScatter.scatter (rebatch geometry (batchShape (first + second) tail))
        (ReducerIndex.ScatterRoles.combine firstRole secondRole)
        (Tensor.map₂ (· + ·) leftBase rightBase) (concatenate tail leftIndices rightIndices)
        (concatenate tail leftUpdates rightUpdates) := by
  rw [OrderedScatter.distinct_word_operation firstRole secondRole distinct]
  exact scatter_combine geometry tail (· + ·) BitVec.add_assoc BitVec.add_comm _ _ _ _ _ _

end TensorRewrite.Theory.ScatterConcat
