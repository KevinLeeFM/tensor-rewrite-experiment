module

public import TensorRewrite.Theory.Concatenation

/-! Bounded coordinate transport and ordered segment laws for arbitrary-axis concatenation. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Equality of the complete framed shapes is exactly equality of the selected extents. -/
theorem shape_eq_iff {rank first second : Nat} (frame : Frame rank) :
    frame.shape first = frame.shape second ↔ first = second := by
  constructor
  · intro same
    have axisSame := congrFun same frame.axis
    simpa [Frame.shape] using axisSame
  · intro same
    cases same
    rfl

/-- Reading a replaced axis returns exactly the replacement coordinate. -/
theorem position_withPosition {rank inputExtent outputExtent : Nat} (frame : Frame rank)
    (index : Index (frame.shape inputExtent)) (position : Fin outputExtent) :
    frame.position (frame.withPosition index position) = position := by
  apply Fin.ext
  simp [Frame.position, Frame.withPosition]

/-- Two axis replacements retain only the final replacement coordinate. -/
theorem withPosition_withPosition {rank first second third : Nat} (frame : Frame rank)
    (index : Index (frame.shape first)) (middle : Fin second) (last : Fin third) :
    frame.withPosition (frame.withPosition index middle) last =
      frame.withPosition index last := by
  funext axis
  apply Fin.ext
  by_cases same : axis = frame.axis <;> simp [Frame.withPosition, same]

/-- Reinstalling the actual selected coordinate recovers the whole original index. -/
theorem withPosition_position {rank extent : Nat} (frame : Frame rank)
    (index : Index (frame.shape extent)) :
    frame.withPosition index (frame.position index) = index := by
  funext axis
  apply Fin.ext
  by_cases same : axis = frame.axis
  · subst axis
    simp [Frame.withPosition, Frame.position]
  · simp [Frame.withPosition, same]

/-- The selected coordinate of any extent-one frame is necessarily zero. -/
theorem withPosition_zero {rank : Nat} (frame : Frame rank) (rest : Index (frame.shape 1)) :
    frame.withPosition rest 0 = rest := by
  have zero : frame.position rest = 0 := by
    apply Fin.ext
    have bound := (frame.position rest).isLt
    omega
  rw [← zero]
  exact withPosition_position frame rest

/-- Rest coordinates are unchanged by arbitrary selected-axis replacement. -/
theorem rest_withPosition {rank first second : Nat} (frame : Frame rank)
    (index : Index (frame.shape first)) (position : Fin second) :
    frame.rest (frame.withPosition index position) = frame.rest index :=
  withPosition_withPosition frame index position 0

/-- A prepared rest coordinate remains itself after inserting any segment coordinate. -/
theorem rest_insert {rank extent : Nat} (frame : Frame rank)
    (rest : Index (frame.shape 1)) (position : Fin extent) :
    frame.rest (frame.withPosition rest position) = rest := by
  rw [rest_withPosition]
  exact withPosition_zero frame rest

/-- Rest plus the selected output coordinate reconstructs the original output index. -/
theorem insert_rest_position {rank extent : Nat} (frame : Frame rank)
    (index : Index (frame.shape extent)) :
    frame.withPosition (frame.rest index) (frame.position index) = index := by
  rw [Frame.rest, withPosition_withPosition, withPosition_position]

/-- Appending operands adds their derived output extents. -/
theorem total_append {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : List (Block frame α)) : total (left ++ right) = total left + total right := by
  induction left with
  | nil => simp [total]
  | cons block blocks ih => simp [total, ih, Nat.add_assoc]

/-- A position in the left operand group is read without consulting the right group. -/
theorem readAt_append_left {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (before : position < total left)
    (bound : position < total (left ++ right)) :
    readAt (left ++ right) rest position bound = readAt left rest position before := by
  induction left generalizing position with
  | nil => simp [total] at before
  | cons block blocks ih =>
    by_cases inside : position < block.extent
    · simp [readAt, inside]
    · simp only [List.cons_append, readAt, dite_eq_right inside]
      exact ih _ _ _

/-- A position after the complete left group subtracts that group's exact extent once. -/
theorem readAt_append_right {rank : Nat} {frame : Frame rank} {α : Type}
    (left right : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (after : total left ≤ position)
    (bound : position < total (left ++ right)) (tailBound : position - total left < total right) :
    readAt (left ++ right) rest position bound =
      readAt right rest (position - total left) tailBound := by
  induction left generalizing position with
  | nil => rfl
  | cons block blocks ih =>
    have inside : ¬ position < block.extent := by
      change block.extent + total blocks ≤ position at after
      omega
    simp only [List.cons_append, readAt, dite_eq_right inside]
    have shifted : total blocks ≤ position - block.extent := by
      change block.extent + total blocks ≤ position at after
      omega
    have same : position - block.extent - total blocks = position - total (block :: blocks) := by
      simp only [total]
      omega
    rw [ih _ shifted _ (by omega)]
    congr 1

/-- Removing zero axis extents preserves the exact output extent, without any nonempty premise. -/
theorem total_filterZero {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) : total (filterZero blocks) = total blocks := by
  induction blocks with
  | nil => rfl
  | cons block blocks ih =>
    by_cases zero : block.extent = 0 <;> simp [filterZero, total, zero, ih] at *

/-- Removing zero axis extents preserves all selected segment values. -/
theorem readAt_filterZero {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (bound : position < total blocks)
    (filteredBound : position < total (filterZero blocks)) :
    readAt (filterZero blocks) rest position filteredBound = readAt blocks rest position bound := by
  induction blocks generalizing position with
  | nil => simp [total] at bound
  | cons block blocks ih =>
    by_cases zero : block.extent = 0
    · have tailBound : position < total blocks := by
        simpa only [total, zero, Nat.zero_add] using bound
      have filteredTail : position < total (filterZero blocks) := by
        rw [total_filterZero]
        exact tailBound
      simpa [filterZero, readAt, zero] using ih position tailBound filteredTail
    · by_cases inside : position < block.extent
      · simp [filterZero, zero, readAt, inside]
      · have tailBound : position - block.extent < total blocks := by
          change position < block.extent + total blocks at bound
          omega
        have filteredTail : position - block.extent < total (filterZero blocks) := by
          rw [total_filterZero]
          exact tailBound
        simpa [filterZero, zero, readAt, inside] using
          ih (position - block.extent) tailBound filteredTail

/-- Positive actual extents are exactly the computed tensor nonemptiness test. -/
theorem hasElements_iff_positive {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) : block.hasElements = true ↔
      ∀ axis, 0 < frame.shape block.extent axis := by
  simp [Block.hasElements, List.all_eq_true, List.mem_finRange]

/-- The test is true exactly when an actual bounded tensor coordinate exists. -/
theorem hasElements_iff_index {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) :
    block.hasElements = true ↔ Nonempty (Index (frame.shape block.extent)) := by
  rw [hasElements_iff_positive]
  constructor
  · intro positive
    exact ⟨fun axis => ⟨0, positive axis⟩⟩
  · rintro ⟨index⟩ axis
    have bound := (index axis).isLt
    omega

/-- Once the other dimensions have coordinates, tensor emptiness is exactly a zero axis extent. -/
theorem hasElements_iff_extent {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) (rest : Index (frame.shape 1)) :
    block.hasElements = true ↔ 0 < block.extent := by
  constructor
  · intro positive
    have axisBound := (hasElements_iff_positive block).mp positive frame.axis
    simpa [Frame.shape] using axisBound
  · intro positive
    apply (hasElements_iff_index block).mpr
    exact ⟨frame.withPosition rest ⟨0, positive⟩⟩

/-- A nonempty tensor frame turns actual empty filtering into zero-axis filtering. -/
theorem filterEmpty_eq_filterZero {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (rest : Index (frame.shape 1)) :
    filterEmpty blocks = filterZero blocks := by
  apply List.filter_congr
  intro block _
  apply Bool.eq_iff_iff.mpr
  rw [hasElements_iff_extent block rest]
  simp only [bne_iff_ne]
  omega

/-- One actual nonempty operand supplies the other-coordinate witness needed for filtering. -/
theorem filterEmpty_of_nonempty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (witness : Block frame α)
    (nonempty : witness.hasElements = true) :
    filterEmpty blocks = filterZero blocks := by
  obtain ⟨index⟩ := (hasElements_iff_index witness).mp nonempty
  exact filterEmpty_eq_filterZero blocks (frame.rest index)

/-- Every valid segment position identifies an actual nonempty operand in the original list. -/
theorem readAt_live_operand {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (bound : position < total blocks) :
    ∃ block ∈ blocks, block.hasElements = true := by
  induction blocks generalizing position with
  | nil => simp [total] at bound
  | cons block blocks ih =>
    by_cases before : position < block.extent
    · refine ⟨block, by simp, (hasElements_iff_index block).mpr ?_⟩
      exact ⟨frame.withPosition rest ⟨position, before⟩⟩
    · have tailBound : position - block.extent < total blocks := by
        change position < block.extent + total blocks at bound
        omega
      obtain ⟨live, member, positive⟩ := ih _ tailBound
      exact ⟨live, List.mem_cons_of_mem _ member, positive⟩

/-- A group packed into one operand retains the exact original coordinate read. -/
theorem read_pack {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (bound : position < total blocks) :
    (pack blocks).values (frame.withPosition rest ⟨position, bound⟩) =
      readAt blocks rest position bound := by
  simp [pack, concatenate, rest_insert, position_withPosition]

/-- Flattening groups preserves the complete derived output extent. -/
theorem total_flatten {rank : Nat} {frame : Frame rank} {α : Type}
    (groups : List (List (Block frame α))) : total (groups.map pack) = total groups.flatten := by
  induction groups with
  | nil => rfl
  | cons blocks groups ih => simp [total, pack, total_append, ih]

/-- Flattening nested concatenations preserves the actual segment read and its order. -/
theorem readAt_flatten {rank : Nat} {frame : Frame rank} {α : Type}
    (groups : List (List (Block frame α))) (rest : Index (frame.shape 1))
    (position : Nat) (bound : position < total (groups.map pack))
    (flatBound : position < total groups.flatten) :
    readAt (groups.map pack) rest position bound =
      readAt groups.flatten rest position flatBound := by
  induction groups generalizing position with
  | nil => simp [total] at bound
  | cons blocks groups ih =>
    change readAt (pack blocks :: groups.map pack) rest position bound =
      readAt (blocks ++ groups.flatten) rest position flatBound
    by_cases before : position < total blocks
    · have beforePack : position < (pack blocks).extent := before
      rw [readAt, dite_eq_left beforePack]
      exact (read_pack blocks rest position before).trans
        (readAt_append_left blocks groups.flatten rest position before flatBound).symm
    · have after : total blocks ≤ position := by omega
      have tailBound : position - total blocks < total (groups.map pack) := by
        change position < total blocks + total (groups.map pack) at bound
        omega
      have tailFlat : position - total blocks < total groups.flatten := by
        rw [← total_flatten]
        exact tailBound
      have afterPack : ¬ position < (pack blocks).extent := before
      rw [readAt, dite_eq_right afterPack]
      exact (ih _ tailBound tailFlat).trans
        (readAt_append_right blocks groups.flatten rest position after flatBound tailFlat).symm

/-- A reflexive extent transport preserves the whole tensor. -/
theorem castTensor_refl {rank extent : Nat} {α : Type} (frame : Frame rank)
    (input : Tensor (frame.shape extent) α) : frame.castTensor rfl input = input := by
  funext index
  change input (frame.withPosition index (frame.position index)) = input index
  rw [withPosition_position]

/-- Consecutive extent-equality transports compose without changing coordinates. -/
theorem castTensor_trans {rank first second third : Nat} {α : Type} (frame : Frame rank)
    (firstSame : first = second) (secondSame : second = third)
    (input : Tensor (frame.shape first) α) :
    frame.castTensor secondSame (frame.castTensor firstSame input) =
      frame.castTensor (firstSame.trans secondSame) input := by
  cases firstSame
  cases secondSame
  simp only [castTensor_refl]

/-- One nonempty operand makes actual-empty filtering preserve the original output extent. -/
theorem total_filterEmpty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (witness : Block frame α)
    (nonempty : witness.hasElements = true) :
    total (filterEmpty blocks) = total blocks := by
  rw [filterEmpty_of_nonempty blocks witness nonempty, total_filterZero]

/-- If all operands are empty, no coordinate of the original output shape exists. -/
theorem no_index_of_all_empty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (empty : ∀ block ∈ blocks, block.hasElements = false) :
    ¬ Nonempty (Index (frame.shape (total blocks))) := by
  rintro ⟨index⟩
  obtain ⟨block, member, live⟩ :=
    readAt_live_operand blocks (frame.rest index) (frame.position index).val
      (frame.position index).isLt
  rw [empty block member] at live
  contradiction

/-- Reading a unary operand list returns its actual bounded operand coordinate. -/
theorem readAt_unary {rank : Nat} {frame : Frame rank} {α : Type}
    (block : Block frame α) (rest : Index (frame.shape 1)) (position : Nat)
    (bound : position < block.extent) (listBound : position < total [block]) :
    readAt [block] rest position listBound =
      block.values (frame.withPosition rest ⟨position, bound⟩) := by
  simp only [readAt, dite_eq_left bound]

/-- Equal operand lists have identical reads under their independently supplied bound proofs. -/
theorem readAt_congr {rank : Nat} {frame : Frame rank} {α : Type}
    {first second : List (Block frame α)} (same : first = second) (rest : Index (frame.shape 1))
    (position : Nat) (firstBound : position < total first) (secondBound : position < total second) :
    readAt first rest position firstBound = readAt second rest position secondBound := by
  cases same
  rfl

/-- A selected contiguous operand group is read after subtracting its exact leading extent. -/
theorem readAt_middle {rank : Nat} {frame : Frame rank} {α : Type}
    (leading selected trailing : List (Block frame α)) (rest : Index (frame.shape 1))
    (position : Nat) (before : position < total selected)
    (bound : total leading + position < total (leading ++ (selected ++ trailing))) :
    readAt (leading ++ (selected ++ trailing)) rest (total leading + position) bound =
      readAt selected rest position before := by
  have selectedBound : position < total (selected ++ trailing) := by
    rw [total_append]
    omega
  have tailBound : total leading + position - total leading < total (selected ++ trailing) := by
    simpa only [Nat.add_sub_cancel_left] using selectedBound
  have after : total leading ≤ total leading + position := by omega
  have right := readAt_append_right leading (selected ++ trailing) rest
    (total leading + position) after bound tailBound
  have step : readAt (leading ++ (selected ++ trailing)) rest (total leading + position) bound =
      readAt (selected ++ trailing) rest position selectedBound := by
    simpa only [Nat.add_sub_cancel_left] using right
  exact step.trans (readAt_append_left selected trailing rest position before selectedBound)

/-- A complete axis interval preserves the tensor and all non-axis coordinates. -/
theorem slice_full {rank extent : Nat} {frame : Frame rank} {α : Type}
    (input : Tensor (frame.shape extent) α) : frame.slice input 0 extent (by omega) = input := by
  funext index
  simp [Frame.slice, withPosition_position]

/-- Transporting an equal extent commutes with the actual bounded Slice map. -/
theorem slice_castTensor {rank first second : Nat} {frame : Frame rank} {α : Type}
    (same : first = second) (input : Tensor (frame.shape first) α) (start length : Nat)
    (firstFits : start + length ≤ first) (secondFits : start + length ≤ second) :
    frame.slice (frame.castTensor same input) start length secondFits =
      frame.slice input start length firstFits := by
  cases same
  rw [castTensor_refl]

end TensorRewrite.Theory.Concatenation
