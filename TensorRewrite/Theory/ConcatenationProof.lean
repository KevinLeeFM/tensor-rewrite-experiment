module

public import TensorRewrite.Theory.ConcatenationLemmas

/-! Tensor graph laws retain derived output shapes, original segment order and all empty-axis
cases. Actual empty-operand filtering requires a nonempty frame witness or separate shape checks.
-/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.Concatenation

open Pilot

/-- Unary concatenation returns its operand with the derived equal output extent. -/
theorem concatenate_unary {rank : Nat} {frame : Frame rank} {α : Type} (block : Block frame α) :
    frame.castTensor (by simp [total]) (concatenate [block]) = block.values := by
  funext index
  simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition, total,
    Nat.add_zero]
  rw [readAt, dite_eq_left (frame.position index).isLt, insert_rest_position]

/-- Zero concatenation extents are safely removed at every rank, including other empty axes. -/
theorem concatenate_filterZero {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) :
    frame.castTensor (total_filterZero blocks) (concatenate (filterZero blocks)) =
      concatenate blocks := by
  funext index
  simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition]
  exact readAt_filterZero blocks (frame.rest index) (frame.position index).val _ _

/-- Actual-empty filtering is sound once a nonempty operand supplies all other coordinates. -/
theorem concatenate_filterEmpty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (witness : Block frame α)
    (nonempty : witness.hasElements = true) :
    frame.castTensor (total_filterEmpty blocks witness nonempty)
        (concatenate (filterEmpty blocks)) =
      concatenate blocks := by
  funext index
  simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition]
  have zeroBound : (frame.position index).val < total (filterZero blocks) := by
    rw [total_filterZero]
    exact (frame.position index).isLt
  exact (readAt_congr (filterEmpty_of_nonempty blocks witness nonempty)
    (frame.rest index) (frame.position index).val _ zeroBound).trans
      (readAt_filterZero blocks (frame.rest index) (frame.position index).val
        (frame.position index).isLt zeroBound)

/-- A nonempty filtered list supplies its own witness and preserves the original output shape. -/
theorem concatenate_filtered {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (nonempty : filterEmpty blocks ≠ []) :
    ∃ same : total (filterEmpty blocks) = total blocks,
      frame.castTensor same (concatenate (filterEmpty blocks)) = concatenate blocks := by
  obtain ⟨block, member⟩ := List.exists_mem_of_ne_nil (filterEmpty blocks) nonempty
  have live : block.hasElements = true := (List.mem_filter.mp member).2
  exact ⟨total_filterEmpty blocks block live, concatenate_filterEmpty blocks block live⟩

/-- A unique actually nonempty operand is the whole value result with derived shape equality. -/
theorem concatenate_only_nonempty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (only : Block frame α)
    (filtered : filterEmpty blocks = [only]) :
    ∃ same : total blocks = only.extent,
      frame.castTensor same (concatenate blocks) = only.values := by
  have member : only ∈ filterEmpty blocks := by rw [filtered]; simp
  have live : only.hasElements = true := (List.mem_filter.mp member).2
  have filteredExtent : total (filterEmpty blocks) = only.extent := by rw [filtered]; simp [total]
  have same := (total_filterEmpty blocks only live).symm.trans filteredExtent
  refine ⟨same, ?_⟩
  calc
    frame.castTensor same (concatenate blocks) =
        frame.castTensor same
          (frame.castTensor (total_filterEmpty blocks only live)
            (concatenate (filterEmpty blocks))) :=
      congrArg (frame.castTensor same) (concatenate_filterEmpty blocks only live).symm
    _ = frame.castTensor ((total_filterEmpty blocks only live).trans same)
          (concatenate (filterEmpty blocks)) := castTensor_trans frame _ _ _
    _ = only.values := by
      funext index
      simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition]
      have onlyBound : (frame.position index).val < total [only] := by
        change (frame.position index).val < only.extent + 0
        have bound := (frame.position index).isLt
        omega
      exact (readAt_congr filtered (frame.rest index) (frame.position index).val _ onlyBound).trans
        ((readAt_unary only (frame.rest index) (frame.position index).val
          (frame.position index).isLt onlyBound).trans
            (congrArg only.values (insert_rest_position frame index)))

/-- An all-empty concatenation has the unique value tensor at its original output shape. -/
theorem concatenate_all_empty {rank : Nat} {frame : Frame rank} {α : Type}
    (blocks : List (Block frame α)) (empty : ∀ block ∈ blocks, block.hasElements = false)
    (replacement : Tensor (frame.shape (total blocks)) α) : concatenate blocks = replacement := by
  funext index
  exact False.elim (no_index_of_all_empty blocks empty ⟨index⟩)

/-- Replacing an all-empty concatenation by a first operand still needs actual shape equality. -/
theorem concatenate_all_empty_first {rank : Nat} {frame : Frame rank} {α : Type}
    (first : Block frame α) (blocks : List (Block frame α))
    (empty : ∀ block ∈ first :: blocks, block.hasElements = false)
    (same : total (first :: blocks) = first.extent) :
    frame.castTensor same (concatenate (first :: blocks)) = first.values := by
  have equal := concatenate_all_empty (first :: blocks) empty
    (frame.castTensor same.symm first.values)
  rw [equal, castTensor_trans, castTensor_refl]

/-- For all-empty operands, first replacement preserves values exactly when full shapes agree. -/
theorem concatenate_all_empty_first_iff {rank : Nat} {frame : Frame rank} {α : Type}
    (first : Block frame α) (blocks : List (Block frame α))
    (empty : ∀ block ∈ first :: blocks, block.hasElements = false) :
    (∃ same : total (first :: blocks) = first.extent,
      frame.castTensor same (concatenate (first :: blocks)) = first.values) ↔
        frame.shape (total (first :: blocks)) = frame.shape first.extent := by
  rw [shape_eq_iff]
  constructor
  · rintro ⟨same, _⟩
    exact same
  · intro same
    exact ⟨same, concatenate_all_empty_first first blocks empty same⟩

/-- Flatten arbitrary groups of nested same-axis concatenations without changing order or shape. -/
theorem concatenate_flatten {rank : Nat} {frame : Frame rank} {α : Type}
    (groups : List (List (Block frame α))) :
    frame.castTensor (total_flatten groups) (concatenate (groups.map pack)) =
      concatenate groups.flatten := by
  funext index
  simp only [Frame.castTensor, concatenate, rest_withPosition, position_withPosition]
  exact readAt_flatten groups (frame.rest index) (frame.position index).val _ _

end TensorRewrite.Theory.Concatenation
