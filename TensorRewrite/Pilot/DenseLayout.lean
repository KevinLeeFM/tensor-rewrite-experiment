module

public import TensorRewrite.Pilot.LinearIndex
public import TensorRewrite.Pilot.PermutationArrays

/-! Untiled dense fixed-cell storage. Layout slots are minor-to-major, while
logical linearization runs major-to-minor. Bytes, packing and memory spaces
are separate from this cell-address model. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot

/-- A legal minor-to-major permutation for an untiled dense array. -/
structure DenseLayout (rank : Nat) where
  /-- Physical slot zero names the most minor logical axis. -/
  minorToMajor : AxisPermutation rank

namespace DenseLayout

/-- Standard dim0-major order: the last logical axis is most minor. -/
def rowMajor (rank : Nat) : DenseLayout rank where
  minorToMajor := {
    outputToInput := Fin.rev
    inputToOutput := Fin.rev
    output_input := Fin.rev_rev
    input_output := Fin.rev_rev
  }

/-- Standard dim0-minor order: the first logical axis is most minor. -/
def columnMajor (rank : Nat) : DenseLayout rank where
  minorToMajor := AxisPermutation.identity rank

/-- Extents in physical major-to-minor order. -/
def orderedShape {rank : Nat} (layout : DenseLayout rank) (shape : Shape rank) : Shape rank :=
  fun slot => shape (layout.minorToMajor.outputToInput slot.rev)

/-- Reorder logical coordinates into the physical major-to-minor convention. -/
def toOrderedIndex {rank : Nat} {shape : Shape rank} (layout : DenseLayout rank)
    (index : Index shape) : Index (layout.orderedShape shape) :=
  fun slot => index (layout.minorToMajor.outputToInput slot.rev)

/-- Recover logical coordinates using the witnessed inverse layout permutation. -/
def fromOrderedIndex {rank : Nat} {shape : Shape rank} (layout : DenseLayout rank)
    (index : Index (layout.orderedShape shape)) : Index shape := fun axis =>
  Fin.cast (by
    change shape (layout.minorToMajor.outputToInput
      (layout.minorToMajor.inputToOutput axis).rev.rev) = shape axis
    rw [Fin.rev_rev, layout.minorToMajor.output_input])
    (index (layout.minorToMajor.inputToOutput axis).rev)

/-- A bounded dense physical cell position for every logical coordinate. -/
def address {rank : Nat} {shape : Shape rank} (layout : DenseLayout rank)
    (index : Index shape) : Fin (LinearIndex.elementCount (layout.orderedShape shape)) :=
  LinearIndex.linearize (layout.orderedShape shape) (layout.toOrderedIndex index)

/-- Physical cells, indexed by the layout-derived storage extent. -/
abbrev Buffer {rank : Nat} (layout : DenseLayout rank) (shape : Shape rank) (α : Type) :=
  Fin (LinearIndex.elementCount (layout.orderedShape shape)) → α

/-- Observe physical cells at logical tensor coordinates. -/
def read {rank : Nat} {shape : Shape rank} {α : Type} (layout : DenseLayout rank)
    (buffer : layout.Buffer shape α) : Tensor shape α := fun index => buffer (layout.address index)

/-- Encode logical values in physical order, deriving coordinates from valid positions. -/
def write {rank : Nat} {shape : Shape rank} {α : Type} (layout : DenseLayout rank)
    (input : Tensor shape α) : layout.Buffer shape α := fun position =>
  input (layout.fromOrderedIndex (LinearIndex.delinearize (layout.orderedShape shape) position))

/-- Same-cell-type bitcast observes one physical buffer through a different layout/shape. -/
def bitcastTensor {inputRank outputRank : Nat} {inputShape : Shape inputRank} {α : Type}
    (inputLayout : DenseLayout inputRank) (outputLayout : DenseLayout outputRank)
    (outputShape : Shape outputRank)
    (sameCount : LinearIndex.elementCount (inputLayout.orderedShape inputShape) =
      LinearIndex.elementCount (outputLayout.orderedShape outputShape))
    (input : Tensor inputShape α) : Tensor outputShape α := fun index =>
  inputLayout.write input ⟨(outputLayout.address index).val, by
    rw [sameCount]
    exact (outputLayout.address index).isLt⟩

/-- The actual source permutation-composition condition on minor-to-major arrays. -/
def MinorOrderMatches {rank : Nat} (permutation : AxisPermutation rank)
    (inputLayout outputLayout : DenseLayout rank) : Prop :=
  AxisArray.compose (AxisArray.ofPermutation permutation)
    (AxisArray.ofPermutation outputLayout.minorToMajor) =
      AxisArray.ofPermutation inputLayout.minorToMajor

/-- Check the finite source order equation without equality of function-valued layouts. -/
instance {rank : Nat} (permutation : AxisPermutation rank)
    (inputLayout outputLayout : DenseLayout rank) :
    Decidable (MinorOrderMatches permutation inputLayout outputLayout) :=
  inferInstanceAs (Decidable (AxisArray.compose (AxisArray.ofPermutation permutation)
    (AxisArray.ofPermutation outputLayout.minorToMajor) =
      AxisArray.ofPermutation inputLayout.minorToMajor))

end DenseLayout
end TensorRewrite.Pilot
