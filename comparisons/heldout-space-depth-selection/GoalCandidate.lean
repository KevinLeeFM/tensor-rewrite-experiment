module
public import SourceFrame
public import ElementCount
public import TensorRewrite.Pilot.Reshape

/-! Candidate statement only. It has not been independently reviewed or frozen. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.SpaceDepthCandidate
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reshape
  TensorRewrite.Theory.Concatenation Heldout.ShapeBridge Heldout.ElementCount
  Heldout.SliceTransport Heldout.OrderedSlices Heldout.ChunkIntervals Heldout.SourceFrame

/-- Mathematical branch data and original-graph well-formedness.
`outerRankAtLeast` is an explicit model restriction, not an established source guard. -/
structure Conditions {rank outerRank : Nat} (shape : Shape rank)
    (inner : Shape (rank + 1)) (outer : Shape outerRank) where
  axes : AxisConditions rank
  count : Nat
  width : Nat
  innerCountAxis : inner axes.split.castSucc = count
  innerWidthAxis : inner axes.split.succ = width
  splitProduct : shape axes.split = count * width
  firstMismatch : count ≠ shape axes.split
  prefixAxes : ∀ j : Fin rank, j.val < axes.split.val → inner j.castSucc = shape j
  suffixAxes : ∀ j : Fin rank, axes.split.val < j.val → inner j.succ = shape j
  countCap : count ≤ 5
  /-- Well-formedness of the original inner reshape. -/
  innerCount : elementCount shape = elementCount inner
  /-- Well-formedness of the original outer reshape after permutation. -/
  outerCount : elementCount shape = elementCount outer
  /-- Model-domain restriction required to interpret the unchecked source indexing. -/
  outerRankAtLeast : rank ≤ outerRank
  /-- Exact precedence of the source's first `rank` output-dimension checks. -/
  outputShape : ∀ j : Fin rank,
    outer ⟨j.val, Nat.lt_of_lt_of_le j.isLt outerRankAtLeast⟩ =
      if axes.moved.val > 0 ∧ j.val + 1 = axes.moved.val then shape j * count
      else if j = axes.split then shape j / count else shape j

/-- A source-detected split cannot have zero chunks, even for empty input tensors. -/
theorem count_positive {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} (plan : Conditions shape inner outer) : 0 < plan.count := by
  apply detected_chunks_positive plan.count plan.width
  simpa [plan.splitProduct] using plan.firstMismatch

/-- Output shape of a logical transpose. -/
def transposedShape {rank : Nat} (shape : Shape rank) (p : AxisPermutation rank) : Shape rank :=
  fun axis => shape (p.outputToInput axis)

/-- The permuted shape matches each original axis at its inverse position. -/
theorem transpose_extents {rank : Nat} (shape : Shape rank) (p : AxisPermutation rank) :
    ∀ axis, transposedShape shape p (p.inputToOutput axis) = shape axis := by
  intro axis
  simp [transposedShape, p.output_input]

/-- Build the original reshape–transpose–reshape graph with actual operators. -/
def original {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) : Tensor outer α :=
  let perm := plan.axes.permutation
  let first := reshapeTensor input inner plan.innerCount
  let transposed := Tensor.transpose perm (transpose_extents inner perm) first
  reshapeTensor transposed outer ((permute_count inner perm).trans (plan.innerCount.symm.trans plan.outerCount))

/-- The actual chunk output frame equals two explicit extent updates. -/
theorem chunk_shape {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) :
    (concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes))) =
      setExtent (setExtent shape plan.axes.split plan.width) (concatAxis plan.axes)
        (plan.count * (setExtent shape plan.axes.split plan.width) (concatAxis plan.axes)) := by
  funext i
  rw [chunk_output_shape]
  simp [setExtent, concat_distinct plan.axes]

/-- Derive, rather than assume, the element count needed for the replacement reshape. -/
theorem chunk_count {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) :
    elementCount ((concatFrame shape plan.axes plan.width).shape
      (total (chunkBlocks (splitFrame shape plan.axes.split)
        (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)))) =
      elementCount outer := by
  rw [chunk_shape]
  exact (redistribute shape plan.axes.split (concatAxis plan.axes) plan.count plan.width
    plan.splitProduct).trans plan.outerCount

/-- Build the actual source-style ordered slice/concatenate/reshape graph. -/
def replacement {rank outerRank : Nat} {shape : Shape rank} {inner : Shape (rank + 1)}
    {outer : Shape outerRank} {α : Type} (plan : Conditions shape inner outer)
    (input : Tensor shape α) : Tensor outer α :=
  let parts := chunkBlocks (splitFrame shape plan.axes.split)
    (framedInput shape plan.axes.split plan.splitProduct input) (concatAxis plan.axes)
  reshapeTensor (concatenate parts) outer (chunk_count plan input)

/-- Exact candidate proposition; no proof is supplied in this module. -/
def Goal : Prop :=
  ∀ (rank outerRank : Nat) (shape : Shape rank) (inner : Shape (rank + 1))
    (outer : Shape outerRank) (plan : Conditions shape inner outer) (α : Type)
    (input : Tensor shape α), original plan input = replacement plan input

#print axioms count_positive
#print axioms transpose_extents
#print axioms chunk_shape
#print axioms chunk_count
end Heldout.SpaceDepthCandidate
