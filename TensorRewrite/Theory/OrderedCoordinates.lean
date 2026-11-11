module

public import Mathlib.Data.List.OfFn
public import Mathlib.Data.List.FinRange
public import TensorRewrite.Theory.ReductionFiberLemmas

/-! Ordered coordinate enumeration, retaining the actual row-major list rather than a sum. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedCoordinates

open Pilot

/-- Enumerate all bounded coordinates with the last logical axis varying fastest. -/
def enumerate {rank : Nat} (shape : Shape rank) : List (Index shape) :=
  (List.finRange (LinearIndex.elementCount shape)).map (LinearIndex.delinearize shape)

/-- A rectangular finite range expands in row-major order, including zero extents. -/
theorem map_finRange_mul {α : Type} (rows columns : Nat) (value : Fin (rows*columns) → α) :
    (List.finRange (rows*columns)).map value = (List.finRange rows).flatMap fun row =>
      (List.finRange columns).map fun column => value (FiniteProduct.join row column) := by
  rw [← List.ofFn_eq_map, List.ofFn_mul]
  simp only [List.ofFn_eq_map, List.flatMap_def]
  rfl

/-- A scalar shape contains exactly one empty coordinate. -/
theorem enumerate_scalar (shape : Shape 0) :
    enumerate shape = [fun axis => Fin.elim0 axis] := rfl

/-- Coordinate enumeration decomposes in first-axis/tail order for any shape function. -/
theorem enumerate_uncons {rank : Nat} (shape : Shape (rank + 1)) :
    enumerate shape = (List.finRange (shape 0)).flatMap fun head =>
      (enumerate (fun axis => shape axis.succ)).map fun tail =>
        (Fin.cases head tail : Index shape) := by
  unfold enumerate
  trans (List.finRange (shape 0)).flatMap fun head =>
    (List.finRange (LinearIndex.elementCount (fun axis => shape axis.succ))).map fun tail =>
      LinearIndex.delinearize shape (FiniteProduct.join head tail)
  · exact map_finRange_mul (shape 0) _ _
  simp only [List.map_map]
  congr 1
  funext head
  congr 1
  funext tail
  change (Fin.cases (FiniteProduct.row (FiniteProduct.join head tail))
    (LinearIndex.delinearize (fun axis => shape axis.succ)
      (FiniteProduct.column (FiniteProduct.join head tail))) : Index shape) =
    (Fin.cases head (LinearIndex.delinearize (fun axis => shape axis.succ) tail) : Index shape)
  exact congrArg₂ (fun (h : Fin (shape 0))
    (t : Fin (LinearIndex.elementCount (fun axis => shape axis.succ))) =>
      (Fin.cases h (LinearIndex.delinearize (fun axis => shape axis.succ) t) : Index shape))
    (FiniteProduct.row_join head tail) (FiniteProduct.column_join head tail)

/-- Mapping coordinate enumeration preserves the same ordered first-axis blocks. -/
theorem enumerate_uncons_map {rank : Nat} {α : Type} (shape : Shape (rank + 1))
    (value : Index shape → α) :
    (enumerate shape).map value = (List.finRange (shape 0)).flatMap fun head =>
      (enumerate (fun axis => shape axis.succ)).map fun tail =>
        value (Fin.cases head tail) := by
  rw [enumerate_uncons, List.map_flatMap]
  simp only [List.map_map]
  rfl

end TensorRewrite.Theory.OrderedCoordinates
