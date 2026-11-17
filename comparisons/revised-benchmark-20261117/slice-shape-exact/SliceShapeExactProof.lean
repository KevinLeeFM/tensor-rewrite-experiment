module

public import SliceShapeExactSpec
import TensorRewrite.Pilot.EmptySliceRefutation

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SliceShape.Exact

private theorem empty_count (stride : Int) (hs : 0 < stride) :
    (stride - 1).tdiv stride = 0 :=
  Int.tdiv_eq_zero_of_lt (by omega) (by omega)

private theorem short_count (span stride : Int)
    (hspan : 0 < span) (hs : span ≤ stride) :
    (span + stride - 1).tdiv stride = 1 := by
  rw [show span + stride - 1 = (span - 1) + 1 * stride by omega,
    Int.tdiv_eq_ediv_of_nonneg (by omega), Int.add_mul_ediv_right _ _ (by omega),
    Int.ediv_eq_zero_of_lt (by omega) (by omega)]
  decide

/-- Redundant-stride removal preserves precisely the declared static
legality domain described in the frozen target. -/
theorem removeRedundantStride_shape : RemoveRedundantStrideShape := by
  intro extent declared axis h
  obtain ⟨hstart, horder, hlimit, hstride, hdecl, hcount⟩ := h
  change IsWellFormed extent declared (removeRedundantStride axis) ↔ _
  unfold removeRedundantStride
  split
  next hguard =>
    have hshort : axis.limit - axis.start ≤ axis.stride := by
      rcases hguard.2 with hs | hs <;> omega
    have hnewCount :
        ({ axis with limit := axis.start + 1, stride := 1 } : Axis).elementCount = 1 := by
      simp [Axis.elementCount, Int.tdiv_one]
      omega
    change (0 ≤ axis.start ∧ axis.start ≤ axis.start + 1 ∧
      axis.start + 1 ≤ extent ∧ 0 < (1 : Int) ∧ 0 ≤ declared ∧
      ({ axis with limit := axis.start + 1, stride := 1 } : Axis).elementCount = declared) ↔ _
    rw [hnewCount]
    change (axis.limit - axis.start + axis.stride - 1).tdiv axis.stride = declared at hcount
    constructor
    · intro hnew
      right
      by_cases hlt : axis.start < axis.limit
      · exact hlt
      · rw [show axis.limit - axis.start + axis.stride - 1 = axis.stride - 1 by omega,
          empty_count _ hstride] at hcount
        omega
    · intro hp
      have hlt : axis.start < axis.limit := hp.resolve_left hguard.1
      rw [short_count (axis.limit - axis.start) axis.stride (by omega) hshort] at hcount
      exact ⟨hstart, by omega, by omega, by omega, hdecl, hcount⟩
  next hguard =>
    refine ⟨fun _ => ?_, fun _ => ⟨hstart, horder, hlimit, hstride, hdecl, hcount⟩⟩
    by_cases hs : axis.stride = 1
    · exact Or.inl hs
    · right
      by_cases hlt : axis.start < axis.limit
      · exact hlt
      · exact False.elim (hguard ⟨hs, Or.inr (by omega)⟩)

/-- A positive span has a last selected point and its count is one plus the
quotient of span minus one, including when the last interval is short. -/
private theorem reverse_nonempty (span stride : Int) (hspan : 0 < span) (hs : 0 < stride) :
    let q := (span - 1).tdiv stride
    0 ≤ q * stride ∧ q * stride ≤ span - 1 ∧
      (span + stride - 1).tdiv stride = q + 1 ∧
      (q * stride + stride).tdiv stride = q + 1 := by
  dsimp only
  rw [Int.tdiv_eq_ediv_of_nonneg (show 0 ≤ span - 1 by omega)]
  let q := (span - 1) / stride
  change 0 ≤ q * stride ∧ q * stride ≤ span - 1 ∧
    (span + stride - 1).tdiv stride = q + 1 ∧
    (q * stride + stride).tdiv stride = q + 1
  have hq : 0 ≤ q := Int.ediv_nonneg (by omega) (by omega)
  have hprod := Int.mul_nonneg hq (show 0 ≤ stride by omega)
  refine ⟨hprod, Int.ediv_mul_le _ (by omega), ?_, ?_⟩
  · rw [show span + stride - 1 = (span - 1) + 1 * stride by omega,
      Int.tdiv_eq_ediv_of_nonneg (by omega), Int.add_mul_ediv_right _ _ (by omega)]
  · rw [Int.tdiv_eq_ediv_of_nonneg (show 0 ≤ q * stride + stride by omega),
      show q * stride + stride = (q + 1) * stride by simp [Int.add_mul],
      Int.mul_ediv_cancel _ (by omega)]

/-- Reverse reordering preserves precisely the declared static legality
domain described in the frozen target. -/
theorem reorderReverse_shape : ReorderReverseShape := by
  intro extent declared axis h
  obtain ⟨hstart, horder, hlimit, hstride, hdecl, hcount⟩ := h
  by_cases hlt : axis.start < axis.limit
  · refine ⟨fun _ => Or.inr hlt, fun _ => ?_⟩
    obtain ⟨hprod, hlast, hold, hnew⟩ :=
      reverse_nonempty (axis.limit - axis.start) axis.stride (by omega) hstride
    simp only [reorderReverse, IsWellFormed, Axis.elementCount]
    change (axis.limit - axis.start + axis.stride - 1).tdiv axis.stride = declared at hcount
    exact ⟨by omega, by omega, by omega, hstride, hdecl, by
      rw [show extent - axis.start -
        (extent - axis.start -
          (axis.start + (axis.limit - axis.start - 1).tdiv axis.stride * axis.stride + 1 -
            axis.start)) + axis.stride - 1 =
        (axis.limit - axis.start - 1).tdiv axis.stride * axis.stride + axis.stride by omega]
      omega⟩
  · have heq : axis.limit = axis.start := by omega
    have hd : declared = 0 := by
      simpa [Axis.elementCount, heq, empty_count _ hstride] using hcount.symm
    by_cases hs : axis.stride = 1
    · refine ⟨fun _ => Or.inl hs, fun _ => ?_⟩
      simp [reorderReverse, IsWellFormed, Axis.elementCount, heq, hd, hs, Int.tdiv_one]
      omega
    · have hstep : (axis.limit - axis.start - 1).tdiv axis.stride = 0 := by
        rw [show axis.limit - axis.start - 1 = -(1 : Int) by omega, Int.neg_tdiv,
          Int.tdiv_eq_zero_of_lt (by decide) (by omega)]
        decide
      refine ⟨fun hnew => ?_, fun hp => False.elim (hp.elim hs hlt)⟩
      have hnewCount : (reorderReverse extent axis).elementCount = 1 := by
        unfold reorderReverse Axis.elementCount
        simp only [hstep, Int.zero_mul, Int.add_zero]
        rw [show extent - axis.start -
          (extent - axis.start - (axis.start + 1 - axis.start)) + axis.stride - 1 =
          axis.stride by omega, Int.tdiv_self (by omega)]
      have := hnew.2.2.2.2.2
      omega

/-- On the preservation domain, removeRedundantStride retains the input
coordinate selected at each admitted output index. -/
theorem removeRedundantStride_coordinate : RemoveRedundantStrideCoordinate := by
  intro extent declared axis h hp j hj hjd
  obtain ⟨hstart, _, _, _, _, hcount⟩ := h
  unfold removeRedundantStride
  split
  next hguard =>
    have hlt : axis.start < axis.limit := hp.resolve_left hguard.1
    have hshort : axis.limit - axis.start ≤ axis.stride := by
      rcases hguard.2 with hs | hs <;> omega
    change (axis.limit - axis.start + axis.stride - 1).tdiv axis.stride = declared at hcount
    rw [short_count (axis.limit - axis.start) axis.stride (by omega) hshort] at hcount
    have hz : j = 0 := by omega
    simp [hz]
  next _ => rfl

/-- Reversing the output position after the transformed slice retains the
unreversed input coordinate of the original slice-after-reverse. -/
theorem reorderReverse_coordinate : ReorderReverseCoordinate := by
  intro extent declared axis h _ j hj hjd
  obtain ⟨_, horder, _, hstride, _, hcount⟩ := h
  change (axis.limit - axis.start + axis.stride - 1).tdiv axis.stride = declared at hcount
  by_cases hlt : axis.start < axis.limit
  · obtain ⟨_, _, hold, _⟩ :=
      reverse_nonempty (axis.limit - axis.start) axis.stride (by omega) hstride
    let q := (axis.limit - axis.start - 1).tdiv axis.stride
    have hpos : declared - 1 - j = q - j := by
      change _ = (axis.limit - axis.start - 1).tdiv axis.stride - j
      omega
    simp only [reorderReverse, hpos, Int.sub_mul, q]
    omega
  · rw [show axis.limit - axis.start + axis.stride - 1 = axis.stride - 1 by omega,
      empty_count _ hstride] at hcount
    omega

#print axioms removeRedundantStride_shape
#print axioms reorderReverse_shape
#print axioms removeRedundantStride_coordinate
#print axioms reorderReverse_coordinate

-- Historical admitted empty witness, replayed with the original retained shape.
example : IsWellFormed 4 0 emptyWitness ∧
    ¬ IsWellFormed 4 0 (removeRedundantStride emptyWitness) ∧
    ¬ IsWellFormed 4 0 (reorderReverse 4 emptyWitness) :=
  ⟨empty_witness_well_formed, remove_redundant_stride_refutes, reorder_reverse_refutes⟩

-- A unit-stride empty endpoint remains legal, including zero input extent.
example : let a : Axis := ⟨0, 0, 1⟩
    IsWellFormed 0 0 a ∧ IsWellFormed 0 0 (removeRedundantStride a) ∧
      IsWellFormed 0 0 (reorderReverse 0 a) := by decide
example : let a : Axis := ⟨4, 4, 1⟩
    IsWellFormed 4 0 a ∧ reorderReverse 4 a = ⟨0, 0, 1⟩ ∧
      IsWellFormed 4 0 (reorderReverse 4 a) := by decide

-- At the opposite stride choice, the endpoint may break the input bounds too.
example : let a : Axis := ⟨4, 4, 2⟩
    IsWellFormed 4 0 a ∧ (removeRedundantStride a).limit = 5 ∧
      (reorderReverse 4 a).start = -1 ∧
      ¬ IsWellFormed 4 0 (removeRedundantStride a) ∧
      ¬ IsWellFormed 4 0 (reorderReverse 4 a) := by decide

-- Admitted non-unit positive controls exercise the selected (single element)
-- and unselected (several elements) stride arms and two reverse lookup points.
example : let a : Axis := ⟨1, 3, 3⟩
    IsWellFormed 6 1 a ∧ removeRedundantStride a = ⟨1, 2, 1⟩ ∧
      IsWellFormed 6 1 (removeRedundantStride a) ∧
      IsWellFormed 6 1 (reorderReverse 6 a) := by decide
example : let a : Axis := ⟨1, 8, 3⟩
    IsWellFormed 9 3 a ∧ removeRedundantStride a = a ∧
      reorderReverse 9 a = ⟨1, 8, 3⟩ ∧
      IsWellFormed 9 3 (reorderReverse 9 a) := by decide
example : let a : Axis := ⟨2, 8, 3⟩
    IsWellFormed 10 2 a ∧ reorderReverse 10 a = ⟨4, 8, 3⟩ ∧
      4 + (2 - 1 - (0 : Int)) * 3 = 10 - 1 - (2 + 0 * 3) ∧
      4 + (2 - 1 - (1 : Int)) * 3 = 10 - 1 - (2 + 1 * 3) ∧
      4 + (1 : Int) * 3 ≠ 10 - 1 - (2 + 1 * 3) := by decide

-- Euclidean rounding would silently remove the historical empty failure.
example : (-(1 : Int)).tdiv 2 = 0 ∧ (-(1 : Int)) / 2 = -1 := by decide

end TensorRewrite.Pilot.SliceShape.Exact
