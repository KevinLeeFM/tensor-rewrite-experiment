module

public import TensorRewrite.Theory.SlicePad
public import Mathlib.Tactic.Ring

/-! Derive the valid output interval and legal Slice/Pad geometry from affine axis parameters. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.SlicePad

/-- Ceiling division is characterized by the exact multiplicative upper bound. -/
theorem ceil_le_iff (position : Int) (stride : Nat) (positive : 0 < stride) (index : Int) :
    ceilDiv position stride ≤ index ↔ position ≤ index * (stride : Int) := by
  have step : (0 : Int) < stride := by omega
  have division := Int.le_ediv_iff_mul_le (a := -index) (b := -position) step
  simp only [Int.neg_mul] at division
  unfold ceilDiv
  omega

/-- Ceiling division is monotone on signed positions for a positive step. -/
theorem ceil_mono (left right : Int) (stride : Nat) (positive : 0 < stride)
    (ordered : left ≤ right) : ceilDiv left stride ≤ ceilDiv right stride := by
  apply (ceil_le_iff left stride positive _).mpr
  have bound := (ceil_le_iff right stride positive (ceilDiv right stride)).mp (by rfl)
  omega

/-- Clipping the two monotone thresholds cannot reverse the valid interval. -/
theorem first_le_last (axis : Axis) : axis.first ≤ axis.last := by
  have ordered := ceil_mono axis.low (axis.low + axis.inputExtent) axis.stride
    axis.stride_pos (by omega)
  unfold Axis.first Axis.last
  omega

/-- The valid interval is clipped to the supplied output extent. -/
theorem last_le_output (axis : Axis) : axis.last ≤ axis.outputExtent := Nat.min_le_left _ _

/-- Exact signed input bounds are equivalent to membership in the derived valid output interval. -/
theorem valid_interval (axis : Axis) (output : Fin axis.outputExtent) :
    axis.first ≤ output.val ∧ output.val < axis.last ↔
      0 ≤ (output.val : Int) * axis.stride - axis.low ∧
        (output.val : Int) * axis.stride - axis.low < axis.inputExtent := by
  have lower := ceil_le_iff axis.low axis.stride axis.stride_pos (output.val : Int)
  have upper := ceil_le_iff (axis.low + axis.inputExtent) axis.stride axis.stride_pos
    (output.val : Int)
  have bound := output.isLt
  unfold Axis.first Axis.last
  omega

/-- The Slice's start is always a legal endpoint, even with no valid samples. -/
theorem start_le_input (axis : Axis) : axis.start ≤ axis.inputExtent := Nat.min_le_left _ _

/-- On a nonempty valid interval the clipped Slice start is the actual affine position. -/
theorem start_cast (axis : Axis) (nonempty : 0 < axis.count) :
    (axis.start : Int) = (axis.first : Int) * axis.stride - axis.low := by
  have ordered := first_le_last axis
  have bound := last_le_output axis
  have inside : axis.first < axis.last := by unfold Axis.count at nonempty; omega
  have valid := (valid_interval axis ⟨axis.first, by omega⟩).mp ⟨by rfl, inside⟩
  dsimp only at valid
  unfold Axis.start
  omega

/-- Every computed Slice coordinate is exactly the affine input coordinate of its valid output. -/
theorem slice_coordinate (axis : Axis) (index : Fin axis.count) :
    ((axis.start + index.val * axis.stride : Nat) : Int) =
      ((axis.first + index.val : Nat) : Int) * axis.stride - axis.low := by
  have nonempty : 0 < axis.count := by have := index.isLt; omega
  rw [Int.natCast_add, Int.natCast_mul, Int.natCast_add, Int.add_mul, start_cast axis nonempty]
  omega

/-- The constructed Slice never reads outside its original input extent. -/
theorem slice_bounded (axis : Axis) (index : Fin axis.count) :
    axis.start + index.val * axis.stride < axis.inputExtent := by
  have ordered := first_le_last axis
  have lastBound := last_le_output axis
  have bounded := index.isLt
  have inside : axis.first + index.val < axis.last := by unfold Axis.count at bounded; omega
  have valid := (valid_interval axis ⟨axis.first + index.val, by omega⟩).mp
    ⟨by change axis.first ≤ axis.first + index.val; omega, inside⟩
  dsimp only at valid
  have same := slice_coordinate axis index
  omega

/-- The padding extents and Slice count reconstruct the original output extent exactly. -/
theorem padded_extent (axis : Axis) :
    axis.first + axis.count + (axis.outputExtent - axis.last) = axis.outputExtent := by
  have := first_le_last axis
  have := last_le_output axis
  unfold Axis.count
  omega

/-- Slice limits stay ordered, including the canonical empty Slice. -/
theorem start_le_limit (axis : Axis) : axis.start ≤ axis.limit := by
  unfold Axis.limit
  split <;> omega

/-- The last selected input coordinate bounds the exclusive Slice limit. -/
theorem limit_le_input (axis : Axis) : axis.limit ≤ axis.inputExtent := by
  by_cases empty : axis.count = 0
  · simpa only [Axis.limit, ite_eq_left empty] using start_le_input axis
  · have positive : 0 < axis.count := by omega
    have bound := slice_bounded axis ⟨axis.count - 1, by omega⟩
    dsimp only at bound
    simp only [Axis.limit, ite_eq_right empty]
    omega

/-- The ordinary start/limit/stride extent calculation returns exactly the derived count. -/
theorem attributes_count (axis : Axis) : axis.attributes.elementCount = (axis.count : Int) := by
  have positive : (0 : Int) < axis.stride := by have := axis.stride_pos; omega
  change (((axis.limit : Int) - axis.start + axis.stride - 1).tdiv axis.stride) = _
  by_cases empty : axis.count = 0
  · have limit : axis.limit = axis.start := by simp [Axis.limit, empty]
    rw [limit, empty]
    simp only [Int.sub_self, Int.zero_add, Int.natCast_zero]
    exact Int.tdiv_eq_zero_of_lt (by omega) (by omega)
  · have predecessor : ((axis.count - 1 : Nat) : Int) = (axis.count : Int) - 1 := by omega
    have numerator : (axis.limit : Int) - axis.start + axis.stride - 1 =
        (axis.count : Int) * axis.stride := by
      simp only [Axis.limit, ite_eq_right empty, Int.natCast_add, Int.natCast_mul]
      rw [predecessor]
      ring
    rw [numerator, Int.mul_tdiv_cancel _ (by omega)]

/-- Computed Slice attributes satisfy the existing Slice well-formedness contract. -/
theorem attributes_valid (axis : Axis) :
    Pilot.SliceShape.IsWellFormed axis.inputExtent axis.count axis.attributes := by
  have ordered := start_le_limit axis
  have bounded := limit_le_input axis
  have positive := axis.stride_pos
  change 0 ≤ (axis.start : Int) ∧ (axis.start : Int) ≤ axis.limit ∧
    (axis.limit : Int) ≤ axis.inputExtent ∧ 0 < (axis.stride : Int) ∧
    0 ≤ (axis.count : Int) ∧ axis.attributes.elementCount = (axis.count : Int)
  exact ⟨by omega, by omega, by omega, by omega, by omega, attributes_count axis⟩

/-- The bounded-coordinate constructor admits exactly the signed in-range positions. -/
theorem bounded_isSome (extent : Nat) (position : Int) :
    (ReductionWindow.boundedIndex? extent position).isSome ↔
      0 ≤ position ∧ position < extent := by
  unfold ReductionWindow.boundedIndex?
  split <;> simp_all

/-- Extracting an admitted bounded coordinate recovers the original signed position. -/
theorem bounded_value (extent : Nat) (position : Int)
    (valid : (ReductionWindow.boundedIndex? extent position).isSome) :
    (((ReductionWindow.boundedIndex? extent position).get valid).val : Int) = position := by
  have bounds := (bounded_isSome extent position).mp valid
  simp only [ReductionWindow.boundedIndex?, dite_eq_left bounds, Option.get_some]
  exact Int.toNat_of_nonneg bounds.1

/-- Padding admits exactly the valid output interval selected for the Slice. -/
theorem pad_interval (axis : Axis) (output : Fin axis.outputExtent) :
    (ReductionWindow.boundedIndex? axis.count ((output.val : Int) - axis.first)).isSome ↔
      axis.first ≤ output.val ∧ output.val < axis.last := by
  rw [bounded_isSome]
  have ordered := first_le_last axis
  unfold Axis.count
  omega

/-- A retained output's Slice-after-Pad coordinate is its original affine input position. -/
theorem coordinate_after_pad (axis : Axis) (output : Fin axis.outputExtent)
    (inside : axis.first ≤ output.val ∧ output.val < axis.last) :
    (axis.start : Int) + (axis.stride : Int) * ((output.val : Int) - axis.first) =
      (output.val : Int) * axis.stride - axis.low := by
  have nonempty : 0 < axis.count := by unfold Axis.count; omega
  rw [start_cast axis nonempty]
  ring

end TensorRewrite.Theory.SlicePad
