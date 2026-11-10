module

public import TensorRewrite.Pilot.Permutation

@[expose] public section

namespace TensorRewrite.Pilot

/-- Length- and range-checked representation of a source permutation array. -/
abbrev AxisArray (rank : Nat) := Vector (Fin rank) rank

namespace AxisArray

/-- Decode signed source axis numbers only after proving their legal range. -/
def decode {rank : Nat} (raw : Vector Int rank)
    (valid : ∀ i : Fin rank, 0 ≤ raw[i] ∧ raw[i] < (rank : Int)) : AxisArray rank :=
  Vector.ofFn fun i => ⟨(raw[i]).toNat, (Int.toNat_lt (valid i).1).mpr (valid i).2⟩

/-- Array specification of ComposePermutations: result[i] = left[right[i]]. -/
def compose {rank : Nat} (left right : AxisArray rank) : AxisArray rank :=
  right.map fun axis => left[axis]

/-- Convert two mutually inverse arrays into a witnessed axis permutation. -/
def toPermutation {rank : Nat} (forward inverse : AxisArray rank)
    (forward_inverse : ∀ i : Fin rank, forward[inverse[i]] = i)
    (inverse_forward : ∀ i : Fin rank, inverse[forward[i]] = i) : AxisPermutation rank where
  outputToInput := fun i => forward[i]
  inputToOutput := fun i => inverse[i]
  output_input := forward_inverse
  input_output := inverse_forward

/-- Tabulate the output-to-input map of a witnessed permutation. -/
def ofPermutation {rank : Nat} (p : AxisPermutation rank) : AxisArray rank :=
  Vector.ofFn p.outputToInput

end AxisArray
end TensorRewrite.Pilot
