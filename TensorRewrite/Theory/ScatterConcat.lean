module

public import TensorRewrite.Theory.OrderedScatterGraph
public import TensorRewrite.Theory.OrderedCoordinates

/-! First-axis tensor concatenation for the ordered full-window Scatter profile. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ScatterConcat

open Pilot

/-- A batch shape with an explicit leading extent and arbitrary shared trailing dimensions. -/
abbrev batchShape {rank : Nat} (count : Nat) (tail : Shape rank) : Shape (rank + 1) :=
  Fin.cases count tail

/-- Embed a coordinate of the left input into the concatenated leading dimension. -/
def leftIndex {rank : Nat} {first : Nat} (second : Nat) (tail : Shape rank)
    (index : Index (batchShape first tail)) : Index (batchShape (first + second) tail) :=
  Fin.cases ⟨(index 0).val, by have bound := (index 0).isLt; exact Nat.lt_add_right _ bound⟩
    (fun axis => index axis.succ)

/-- Embed a coordinate of the right input after the entire leading extent of the left input. -/
def rightIndex {rank : Nat} (first : Nat) {second : Nat} (tail : Shape rank)
    (index : Index (batchShape second tail)) : Index (batchShape (first + second) tail) :=
  Fin.cases ⟨first + (index 0).val, Nat.add_lt_add_left (index 0).isLt first⟩
    (fun axis => index axis.succ)

/-- Concatenate actual tensor values along their leading batch dimension, with no event lists
as inputs. The vector components and window coordinates remain inside the payload type. -/
def concatenate {rank first second : Nat} {α : Type} (tail : Shape rank)
    (left : Tensor (batchShape first tail) α) (right : Tensor (batchShape second tail) α) :
    Tensor (batchShape (first + second) tail) α := fun index =>
  if before : (index 0).val < first then
    left (Fin.cases ⟨(index 0).val, before⟩ (fun axis => index axis.succ))
  else
    right (Fin.cases ⟨(index 0).val - first, by
      change (index 0).val - first < second
      have bound := (index 0).isLt
      change (index 0).val < first + second at bound
      omega⟩ (fun axis => index axis.succ))

/-- Replace only the batch shape of a Scatter geometry; operand, window and signed axes stay
identical. This does not insert or permute any update-window dimension. -/
abbrev rebatch {rank oldBatchRank newBatchRank indexSize : Nat}
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (shape : Shape newBatchRank) :
    OrderedScatter.Plan rank newBatchRank indexSize where
  operandShape := geometry.operandShape
  batchShape := shape
  windowShape := geometry.windowShape
  indexAxes := geometry.indexAxes
  injective := geometry.injective

end TensorRewrite.Theory.ScatterConcat
