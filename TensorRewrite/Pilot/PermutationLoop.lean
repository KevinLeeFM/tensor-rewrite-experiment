import TensorRewrite.Pilot.PermutationArrays

namespace TensorRewrite.Pilot.AxisArray

/-- State after count iterations of the source's empty-array/push_back loop.
Capacity reservation is omitted because it does not change logical contents. -/
def composePrefix {rank : Nat} (left right : AxisArray rank) :
    (count : Nat) → count ≤ rank → Array (Fin rank)
  | 0, _ => #[]
  | count + 1, bound =>
    (composePrefix left right count (by omega)).push
      left[right[(⟨count, by omega⟩ : Fin rank)]]

/-- Run the logical source loop through every coordinate. -/
def composeLoop {rank : Nat} (left right : AxisArray rank) : Array (Fin rank) :=
  composePrefix left right rank (Nat.le_refl rank)

end TensorRewrite.Pilot.AxisArray
