module
public import GoalCandidate
public import CoordinateChunkAdapter
public import TensorRewrite.Pilot.LinearIndexLemmas
/-! Work toward the frozen goal, separate from the frozen baseline. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.IndexTransportAttempt
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
 TensorRewrite.Pilot.FiniteProduct TensorRewrite.Theory.Concatenation
 Heldout.SliceTransport Heldout.OrderedSlices Heldout.ChunkIntervals Heldout.SourceFrame
 Heldout.SpaceDepthCandidate Heldout.CoordinateChunkAdapter Heldout.ElementCount

/-- A logical reshape preserves the packed numeric coordinate at arbitrary ranks. -/
theorem reshape_linear_value {inputRank outputRank : Nat} (inputShape : Shape inputRank)
    (outputShape : Shape outputRank) (same : elementCount inputShape = elementCount outputShape)
    (out : Index outputShape) :
    (linearize inputShape (reshapeIndex inputShape outputShape same out)).val =
      (linearize outputShape out).val := by
  simp only [reshapeIndex, TensorRewrite.Pilot.LinearIndex.linearize_delinearize]

/-- Transpose transports an input coordinate from its inverse-permuted output axis. -/
theorem transpose_coordinate_value {rank : Nat} {inputShape outputShape : Shape rank}
    (p : AxisPermutation rank) (extents : ∀ i, outputShape (p.inputToOutput i) = inputShape i)
    (index : Index outputShape) (i : Fin rank) :
    (Tensor.transposeIndex p extents index i).val = (index (p.inputToOutput i)).val := rfl

/-- The input coordinate computed by the original graph. -/
def originalIndex {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) (out : Index outer) : Index shape :=
  let perm := plan.axes.permutation
  reshapeIndex shape inner plan.innerCount
    (Tensor.transposeIndex perm (transpose_extents inner perm)
      (reshapeIndex (transposedShape inner perm) outer
        ((permute_count inner perm).trans (plan.innerCount.symm.trans plan.outerCount)) out))

/-- The input coordinate selected by the actual concatenation coordinate. -/
def replacementIndex {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) : Index shape :=
  let source := splitFrame shape plan.axes.split
  let axis := concatAxis plan.axes
  let framed := framedInput shape plan.axes.split plan.splitProduct input
  let frame := concatFrame shape plan.axes plan.width
  let parts := chunkBlocks source framed axis
  let index := reshapeIndex (frame.shape (total parts)) outer (chunk_count plan input) out
  let q := Fin.cast (chunkBlocks_total source framed axis) (frame.position index)
  let idx := sourceIndex source axis (interval plan.count plan.width (row q))
    (frame.withPosition (frame.rest index) (column q))
  fun i => Fin.cast (congrFun (source_shape shape plan.axes.split plan.splitProduct) i) (idx i)

/-- The original graph reads exactly its composed coordinate. -/
theorem original_read {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) : original plan input out = input (originalIndex plan out) := rfl

/-- The replacement graph reads the source coordinate selected by quotient and remainder. -/
theorem replacement_read {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) (out : Index outer) : replacement plan input out = input (replacementIndex plan input out) := by
  simp only [replacement, reshapeTensor, concatenate]
  rw [select_coordinate]
  rfl

/-- Coordinate equality is sufficient for the two actual reads at this output index. -/
theorem read_equal_of_index_equal {rank outerRank : Nat} {shape : Shape rank}
    {inner : Shape (rank + 1)} {outer : Shape outerRank} {α : Type}
    (plan : Conditions shape inner outer) (input : Tensor shape α) (out : Index outer)
    (indexEquality : originalIndex plan out = replacementIndex plan input out) :
    original plan input out = replacement plan input out := by
  rw [original_read, replacement_read, indexEquality]

#print axioms reshape_linear_value
#print axioms transpose_coordinate_value
#print axioms read_equal_of_index_equal
#print axioms original_read
#print axioms replacement_read
end Heldout.IndexTransportAttempt
