module

public import TensorRewrite.Theory.LatticeIndex
public import TensorRewrite.Pilot.IndexMapLemmas
public import Mathlib.Tactic.Ring

/-! Bounded tensor Pad with signed edge padding and nonnegative interior padding. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.SignedPad

open Pilot Theory

/-- Paper Pad computes the occupied span with no interior holes when the input is empty. -/
def extent (size : Nat) (low high : Int) (interior : Nat) : Int :=
  size + max 0 ((size : Int) - 1) * interior + low + high

/-- Per-axis Pad attributes with the artifact's derived nonnegative output shape. -/
structure Params {rank : Nat} (inputShape outputShape : Shape rank) where
  low : Fin rank → Int
  high : Fin rank → Int
  interior : Fin rank → Nat
  shape : ∀ axis, (outputShape axis : Int) =
    extent (inputShape axis) (low axis) (high axis) (interior axis)

/-- Decode precisely occupied positions; a missing coordinate means the fill value. -/
def sample (size : Nat) (low : Int) (interior : Nat) (position : Int) : Option (Fin size) :=
  LatticeIndex.decode? size (interior + 1) (by omega) (position - low)

/-- Occupied positions are exactly low plus an original coordinate times interior spacing. -/
theorem sample_some (size : Nat) (low : Int) (interior : Nat) (position : Int)
    (index : Fin size) :
    sample size low interior position = some index ↔
      position = low + (index.val : Int) * (interior + 1) := by
  unfold sample
  rw [LatticeIndex.decode_eq_some_iff]
  simp only [Nat.cast_add, Nat.cast_one]
  omega

/-- For a unit input axis, changing interior spacing does not change its only occupied point. -/
theorem sample_unit (low position : Int) (first second : Nat) :
    sample 1 low first position = sample 1 low second position := by
  apply Option.ext
  intro index
  rw [sample_some, sample_some]
  have zero : index.val = 0 := by have bound := index.isLt; omega
  simp only [zero, Nat.cast_zero, zero_mul, add_zero]

/-- The same fact applies when the unit extent is carried by a shape expression. -/
theorem sample_unit_size (size : Nat) (unit : size = 1) (low position : Int)
    (first second : Nat) : sample size low first position = sample size low second position := by
  subst size
  exact sample_unit low position first second

/-- The paper's Pad shape does not depend on interior spacing on a unit input axis. -/
theorem extent_unit (low high : Int) (first second : Nat) :
    extent 1 low high first = extent 1 low high second := by
  simp [extent]

/-- Collect the independently bounded coordinates selected by Pad. -/
def selected {rank : Nat} {inputShape outputShape : Shape rank}
    (params : Params inputShape outputShape) (output : Index outputShape) :
    Option (Index inputShape) :=
  LatticeIndex.assemble? fun axis => sample (inputShape axis) (params.low axis)
    (params.interior axis) (output axis).val

/-- The signed Pad graph returns the original tensor value or the specified fill. -/
def tensor {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (params : Params inputShape outputShape) (fill : α) (input : Tensor inputShape α) :
    Tensor outputShape α := fun output =>
  match selected params output with
  | some index => input index
  | none => fill

/-- `pad/rule02`: spacing on singleton axes is unobservable, even with signed edges. -/
theorem unit_interior {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (first second : Params inputShape outputShape)
    (sameLow : ∀ axis, first.low axis = second.low axis)
    (spacing : ∀ axis, first.interior axis = second.interior axis ∨ inputShape axis = 1)
    (fill : α) (input : Tensor inputShape α) :
    tensor first fill input = tensor second fill input := by
  funext output
  have samples : (fun axis => sample (inputShape axis) (first.low axis) (first.interior axis)
        (output axis).val) =
      (fun axis => sample (inputShape axis) (second.low axis) (second.interior axis)
        (output axis).val) := by
    funext axis
    rw [sameLow axis]
    rcases spacing axis with same | unit
    · rw [same]
    · exact sample_unit_size (inputShape axis) unit (second.low axis) (output axis).val
        (first.interior axis) (second.interior axis)
  unfold tensor selected
  rw [samples]

/-- Every valid static Slice coordinate is strictly below its exclusive limit. -/
theorem coordinate_lt_limit {extent length : Int} {axis : SliceShape.Axis}
    (valid : SliceShape.IsWellFormed extent length axis) (index : Int)
    (_nonnegative : 0 ≤ index) (bounded : index < length) :
    axis.start + axis.stride * index < axis.limit := by
  rcases valid with ⟨startNonnegative, ordered, limited, positive, outNonnegative, count⟩
  have numerator : 0 ≤ axis.limit - axis.start + axis.stride - 1 := by omega
  have product : axis.stride * length ≤ axis.limit - axis.start + axis.stride - 1 := by
    rw [← count]
    exact Int.mul_tdiv_self_le numerator
  have step : axis.stride * (index + 1) ≤ axis.stride * length :=
    Int.mul_le_mul_of_nonneg_left (by omega) (by omega)
  rw [Int.mul_add, Int.mul_one] at step
  omega

/-- Positions outside the paper's occupied span cannot sample an original input value. -/
theorem sample_outside (size : Nat) (low position : Int) (interior : Nat)
    (outside : position < low ∨
      low + (size : Int) + ((size : Int) - 1) * interior ≤ position) :
    sample size low interior position = none := by
  cases found : sample size low interior position with
  | none => rfl
  | some index =>
    have location := (sample_some size low interior position index).mp found
    have bound := index.isLt
    have indexBound : (index.val : Int) ≤ (size : Int) - 1 := by omega
    have spacingNonnegative : (0 : Int) ≤ (interior : Int) + 1 := by omega
    have product := Int.mul_le_mul_of_nonneg_right indexBound spacingNonnegative
    have productNonnegative : 0 ≤ (index.val : Int) * ((interior : Int) + 1) :=
      Int.mul_nonneg (by omega) spacingNonnegative
    have normalized : ((size : Int) - 1) * ((interior : Int) + 1) + 1 =
        (size : Int) + ((size : Int) - 1) * interior := by ring
    omega

/-- `slice/rule05`: a Slice wholly outside one occupied axis is a fill tensor. -/
theorem slice_outside {rank : Nat} {inputShape paddedShape outputShape : Shape rank} {α : Type}
    (params : Params inputShape paddedShape) (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (paddedShape axis) (outputShape axis) (axes axis))
    (axis : Fin rank)
    (outside : (axes axis).limit ≤ params.low axis ∨
      params.low axis + (inputShape axis : Int) +
        ((inputShape axis : Int) - 1) * params.interior axis ≤ (axes axis).start)
    (fill : α) (input : Tensor inputShape α) :
    (fun output => tensor params fill input (IndexMaps.sliceIndex axes valid output)) =
      Tensor.constant fill := by
  funext output
  let position := IndexMaps.sliceIndex axes valid output
  have coordinate := IndexMaps.sliceIndex_val axes valid output axis
  have bound := (output axis).isLt
  have beforeLimit := coordinate_lt_limit (valid axis) (output axis).val (by omega) (by omega)
  have positive := (valid axis).2.2.2.1
  have product : 0 ≤ (axes axis).stride * ((output axis).val : Int) :=
    Int.mul_nonneg (by omega) (by omega)
  have outsidePosition : ((position axis).val : Int) < params.low axis ∨
      params.low axis + (inputShape axis : Int) +
        ((inputShape axis : Int) - 1) * params.interior axis ≤ (position axis).val := by
    dsimp only [position]
    omega
  have absent := sample_outside (inputShape axis) (params.low axis) (position axis).val
    (params.interior axis) outsidePosition
  have notAll : ¬ (∀ i, (sample (inputShape i) (params.low i) (params.interior i)
      (position i).val).isSome) := by
    intro all
    have chosen := all axis
    rw [absent] at chosen
    contradiction
  unfold tensor selected LatticeIndex.assemble?
  rw [dite_eq_right notAll]
  rfl

/-- Zero padding preserves the exact size of a newly broadcast axis. -/
theorem extent_zero (size : Nat) : extent size 0 0 0 = size := by
  simp [extent]

/-- A zero-padded extra axis always selects its original coordinate. -/
theorem sample_identity (size : Nat) (index : Fin size) :
    sample size 0 0 index.val = some index := by
  apply (sample_some size 0 0 index.val index).mpr
  simp

/-- All unpadded broadcast-axis coordinates are selected unchanged. -/
theorem extra_selected {rank : Nat} (shape : Shape rank) (output : Index shape) :
    LatticeIndex.assemble? (fun axis => sample (shape axis) 0 0 (output axis).val) =
      some output := by
  apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
  intro axis
  exact sample_identity (shape axis) (output axis)

/-- Pad a tensor broadcast along an unpadded extra axis group, using actual Pad samples. -/
def padBroadcast {rank extraRank : Nat} {inputShape outputShape : Shape rank}
    {α : Type} (params : Params inputShape outputShape) (extraShape : Shape extraRank)
    (fill : α) (input : Tensor inputShape α) : Index outputShape → Index extraShape → α :=
  fun output extra =>
    match selected params output,
        LatticeIndex.assemble? (fun axis => sample (extraShape axis) 0 0 (extra axis).val) with
    | some index, some _ => input index
    | _, _ => fill

/-- `pad/rule03`: zero-padded broadcast axes may be added after the other axes are padded. -/
theorem pad_broadcast {rank extraRank : Nat} {inputShape outputShape : Shape rank}
    {α : Type} (params : Params inputShape outputShape) (extraShape : Shape extraRank)
    (fill : α) (input : Tensor inputShape α) :
    padBroadcast params extraShape fill input =
      fun output _ => tensor params fill input output := by
  funext output extra
  unfold padBroadcast tensor
  rw [extra_selected]
  cases selected params output <;> rfl

/-- Negative low/high Pad edges become valid Slice bounds on the original input axis. -/
theorem negative_crop_valid (size output : Nat) (low high : Int)
    (negativeLow : low < 0) (negativeHigh : high < 0)
    (shape : (output : Int) = size + low + high) :
    SliceShape.IsWellFormed size output ⟨-low, size + high, 1⟩ := by
  unfold SliceShape.IsWellFormed SliceShape.Axis.elementCount
  simp
  omega

/-- An unchanged axis is selected with the whole-axis unit-stride Slice. -/
theorem full_axis_valid (size : Nat) : SliceShape.IsWellFormed size size ⟨0, size, 1⟩ := by
  simp [SliceShape.IsWellFormed, SliceShape.Axis.elementCount]

/-- `pad/rule04`: translate Pad's low edge through a valid Slice, axis by axis. -/
theorem pad_shift {rank : Nat} {inputShape outputShape intermediateShape : Shape rank} {α : Type}
    (first : Params inputShape outputShape) (second : Params inputShape intermediateShape)
    (axes : Fin rank → SliceShape.Axis)
    (valid : ∀ axis, SliceShape.IsWellFormed (intermediateShape axis)
      (outputShape axis) (axes axis))
    (starts : ∀ axis, (axes axis).start = second.low axis - first.low axis)
    (strides : ∀ axis, (axes axis).stride = 1)
    (interiors : ∀ axis, first.interior axis = second.interior axis)
    (fill : α) (input : Tensor inputShape α) :
    tensor first fill input = fun output =>
      tensor second fill input (IndexMaps.sliceIndex axes valid output) := by
  funext output
  have samples : (fun axis => sample (inputShape axis) (first.low axis) (first.interior axis)
        (output axis).val) =
      (fun axis => sample (inputShape axis) (second.low axis) (second.interior axis)
        (IndexMaps.sliceIndex axes valid output axis).val) := by
    funext axis
    have coordinate := IndexMaps.sliceIndex_val axes valid output axis
    rw [starts axis, strides axis] at coordinate
    simp only [one_mul] at coordinate
    have offsets : ((output axis).val : Int) - first.low axis =
        ((IndexMaps.sliceIndex axes valid output axis).val : Int) - second.low axis := by omega
    unfold sample
    rw [interiors axis, offsets]
  unfold tensor selected
  rw [samples]

#print axioms negative_crop_valid
#print axioms full_axis_valid
#print axioms pad_shift
#print axioms extent_zero
#print axioms sample_identity
#print axioms extra_selected
#print axioms pad_broadcast
#print axioms coordinate_lt_limit
#print axioms sample_outside
#print axioms slice_outside
#print axioms sample_some
#print axioms sample_unit
#print axioms sample_unit_size
#print axioms extent_unit
#print axioms unit_interior

end TensorRewrite.PaperComparison.SignedPad
