module
import CoordinateChunkAdapter
open TensorRewrite.Pilot.FiniteProduct Heldout.CoordinateBridge
set_option autoImplicit false
namespace Heldout.CoordinateBridge.Tests

/-- First and last positions select the first and last blocks and local coordinates. -/
example : (row (Fin.cast (show 12 = 3 * 4 by decide) ⟨0, by decide⟩)).val = 0 := by decide
example : (column (Fin.cast (show 12 = 3 * 4 by decide) ⟨0, by decide⟩)).val = 0 := by decide
example : (row (Fin.cast (show 12 = 3 * 4 by decide) ⟨11, by decide⟩)).val = 2 := by decide
example : (column (Fin.cast (show 12 = 3 * 4 by decide) ⟨11, by decide⟩)).val = 3 := by decide
/-- Crossing a block boundary advances the quotient and resets the remainder. -/
example : (row (⟨4, by decide⟩ : Fin (3 * 4))).val = 1 := by decide
example : (column (⟨4, by decide⟩ : Fin (3 * 4))).val = 0 := by decide
/-- A one-block coordinate has block number zero; zero-factor domains are empty. -/
example : (row (⟨3, by decide⟩ : Fin (1 * 4))).val = 0 := by decide
example : ¬ Nonempty (Fin (0 * 4)) := no_position_zero_rows 4
example : ¬ Nonempty (Fin (3 * 0)) := no_position_zero_columns 3
/-- Interchanging quotient and remainder gives the wrong block at this position. -/
example : (row (⟨6, by decide⟩ : Fin (3 * 4))).val ≠
    (column (⟨6, by decide⟩ : Fin (3 * 4))).val := by decide
end Heldout.CoordinateBridge.Tests
