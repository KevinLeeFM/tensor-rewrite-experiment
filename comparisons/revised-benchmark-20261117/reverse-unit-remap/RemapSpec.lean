module
public import UnitSpec
public import TensorRewrite.Pilot.Indexing
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ReverseRemap
open TensorRewrite.Pilot BroadcastUnits
/-- Mathematical meaning of CountElementsLessThan on the increasing inserted vector. -/
def ordinal {n : Nat} (k : Fin n → Bool) (d : Fin n) : Nat :=
  d.val - ((positions (fun j => !k j)).filter (fun j => decide (j < d))).length
/-- Raw output order and integer axis numbers before any legality coercion. -/
def emitted {n : Nat} (t : Shape n) (k : Fin n → Bool) (dims : List (Fin n)) : List Nat :=
  (dims.filter (fun j => decide (t j ≠ 1))).map (ordinal k)
/-- The formula computes the rank in the retained array. -/
def OrdinalGoal : Prop := ∀ {n : Nat} (k : Fin n → Bool) (i : Fin (positions k).length),
  ordinal k ((positions k)[i]) = i.val
/-- Layout-insensitive, static ordered-unit descriptor. Reverse dimensions preserve caller order.
    Counts are the valid reshape guard; the retained shape is the operand shape. -/
def Target : Prop := ∀ {n : Nat} (t : Shape n) (k : Fin n → Bool)
    (_ : ∀ j, k j = false → t j = 1)
    (eq : LinearIndex.elementCount (keptShape t k) = LinearIndex.elementCount t)
    (dims : List (Fin n)) (α : Type) (x : Tensor (keptShape t k) α),
    (∀ d ∈ emitted t k dims, d < (positions k).length) ∧
    (dims.Nodup → (emitted t k dims).Nodup) ∧
    Tensor.reverse (Tensor.axisMask dims) (Reshape.reshapeTensor x t eq) =
      Reshape.reshapeTensor (Tensor.reverse (fun i => decide (i.val ∈ emitted t k dims)) x) t eq
end RevisedBenchmark.ReverseRemap
