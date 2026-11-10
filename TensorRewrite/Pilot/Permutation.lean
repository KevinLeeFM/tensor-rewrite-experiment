module

public import TensorRewrite.Pilot.Indexing

@[expose] public section

namespace TensorRewrite.Pilot

/-- An axis permutation with both inverse laws explicit. -/
structure AxisPermutation (rank : Nat) where
  outputToInput : Fin rank → Fin rank
  inputToOutput : Fin rank → Fin rank
  output_input : ∀ axis, outputToInput (inputToOutput axis) = axis
  input_output : ∀ axis, inputToOutput (outputToInput axis) = axis

namespace AxisPermutation

/-- The identity permutation. -/
def identity (rank : Nat) : AxisPermutation rank where
  outputToInput := id
  inputToOutput := id
  output_input := fun _ => rfl
  input_output := fun _ => rfl

/-- First apply p to tensor axes, then q. -/
def comp {rank : Nat} (p q : AxisPermutation rank) : AxisPermutation rank where
  outputToInput := fun axis => p.outputToInput (q.outputToInput axis)
  inputToOutput := fun axis => q.inputToOutput (p.inputToOutput axis)
  output_input := by
    intro axis
    rw [q.output_input, p.output_input]
  input_output := by
    intro axis
    rw [p.input_output, q.input_output]

end AxisPermutation

namespace Tensor

variable {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}

/-- Map output coordinates to input coordinates, carrying each extent equality. -/
def transposeIndex (p : AxisPermutation rank)
    (extents : ∀ axis, outputShape (p.inputToOutput axis) = inputShape axis)
    (index : Index outputShape) : Index inputShape :=
  fun axis => Fin.cast (extents axis) (index (p.inputToOutput axis))

/-- Logical transpose. Extents and permutation legality are checked by its type. -/
def transpose (p : AxisPermutation rank)
    (extents : ∀ axis, outputShape (p.inputToOutput axis) = inputShape axis)
    (x : Tensor inputShape α) : Tensor outputShape α := reindex (transposeIndex p extents) x

end Tensor
end TensorRewrite.Pilot
