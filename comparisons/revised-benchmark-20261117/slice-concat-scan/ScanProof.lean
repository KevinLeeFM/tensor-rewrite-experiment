module
public import ScanSpec

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ConcatScan
open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation
variable {r : Nat} {f : Frame r} {α : Type}

/-- The end scan takes an initial segment covering its inclusive limit. -/
private theorem finish_sound (bs : List (Block f α)) (hi : Nat) (p t : List (Block f α))
    (found : finish bs hi = some (p,t)) : bs = p ++ t ∧ hi ≤ total p := by
  induction bs generalizing hi p t with
  | nil => simp [finish] at found
  | cons b bs ih =>
    simp only [finish] at found
    split at found
    · cases found
      exact ⟨rfl, by simp [total]; assumption⟩
    · rename_i later
      cases rec : finish bs (hi - b.extent) with
      | none => simp [rec] at found
      | some pair =>
        obtain ⟨picked,tail⟩ := pair
        simp [rec] at found
        obtain ⟨rfl,rfl⟩ := found
        obtain ⟨eq,covers⟩ := ih _ _ _ rec
        exact ⟨by simp [eq], by simp only [total]; omega⟩

/-- A successful scan preserves order, skips at most the start, and covers the limit. -/
private theorem scan_sound (bs : List (Block f α)) (lo hi : Nat) (c : Cut (Block f α))
    (found : scan bs lo hi = some c) :
    bs = c.leading ++ (c.selected ++ c.trailing) ∧
      total c.leading ≤ lo ∧ hi ≤ total c.leading + total c.selected := by
  induction bs generalizing lo hi c with
  | nil => simp [scan] at found
  | cons b bs ih =>
    simp only [scan] at found
    split at found
    · cases rec : finish (b::bs) hi with
      | none => simp [rec] at found
      | some pair =>
        obtain ⟨p,t⟩ := pair
        simp [rec] at found
        subst c
        obtain ⟨eq,covers⟩ := finish_sound _ _ _ _ rec
        exact ⟨eq,Nat.zero_le _,by simpa [total] using covers⟩
    · split at found
      · cases found
      · cases rec : scan bs (lo-b.extent) (hi-b.extent) with
        | none => simp [rec] at found
        | some d =>
          simp [rec] at found
          subst c
          obtain ⟨eq,before,covers⟩ := ih _ _ _ rec
          exact ⟨by simp [eq],by change b.extent + total d.leading ≤ lo; omega,
            by change hi ≤ b.extent + total d.leading + total d.selected; omega⟩

private theorem slice_start_congr {extent a b : Nat} (x : Tensor (f.shape extent) α)
    (len : Nat) (ab : a = b) (ha : a + len ≤ extent) (hb : b + len ≤ extent) :
    f.slice x a len ha = f.slice x b len hb := by cases ab; rfl

/-- Shift the global start by the derived prefix and crop the selected operands. -/
theorem subrange : Subrange := by
  intro r f α bs lo hi ordered bound c found
  obtain ⟨parts,before,covers⟩ := scan_sound _ _ _ _ found
  have fits : lo - total c.leading + (hi-lo) ≤ total c.selected := by omega
  refine ⟨fits, ?_⟩
  subst bs
  have shift : total c.leading + (lo - total c.leading) = lo := by omega
  refine (slice_start_congr _ _ shift.symm _ (by omega)).trans ?_
  exact slice_selected c.leading c.selected c.trailing (lo - total c.leading) (hi-lo) fits

/-- A unary selected span replaces concatenation by the actual operand before slicing. -/
theorem unary (bs : List (Block f α)) (lo hi : Nat) (ordered : lo ≤ hi)
    (bound : hi ≤ total bs) (c : Cut (Block f α)) (b : Block f α)
    (found : scan bs lo hi = some c) (one : c.selected = [b]) :
    ∃ h : lo - total c.leading + (hi-lo) ≤ b.extent,
    f.slice (concatenate bs) lo (hi-lo) (by omega) =
      f.slice b.values (lo - total c.leading) (hi-lo) h := by
  obtain ⟨leading,selected,trailing⟩ := c
  change selected = [b] at one
  subst selected
  obtain ⟨fits,eq⟩ := subrange bs lo hi ordered bound _ found
  have fits' : lo - total leading + (hi-lo) ≤ b.extent := by simpa [total] using fits
  exact ⟨fits', eq.trans (slice_unary _ _ _ fits')⟩

/-- Selecting one full operand forces zero local shift. -/
theorem exactPiece : Exact := by
  intro r f α bs lo hi ordered bound c b found one size
  obtain ⟨parts,before,covers⟩ := scan_sound _ _ _ _ found
  rw [one] at parts covers
  simp [total] at covers
  have start : lo = total c.leading := by omega
  subst bs
  subst lo
  exact slice_exact_piece _ _ _

private def line : Frame 1 := ⟨fun _ => 1, 0⟩
private def segment (width base : Nat) : Block line Nat :=
  ⟨width, fun i => base + (line.position i).val⟩
private def operands := [segment 2 10, segment 2 20, segment 0 30, segment 3 40]
private def widths (bs : List (Block line Nat)) (lo hi : Nat) :=
  (scan bs lo hi).map fun c =>
    (c.leading.map Block.extent, c.selected.map Block.extent, c.trailing.map Block.extent)

-- Exact interior operand, precise endpoint, and multi-operand span across a zero block.
example : widths operands 2 4 = some ([2], [2], [0,3]) := by decide
example : widths operands 3 5 = some ([2], [2,0,3], []) := by decide
-- Just at the boundary the scan reaches the end before finding a strict start.
example : widths operands 2 2 = none := by decide
-- Inside a block, an empty interval does find a start.
example : widths operands 3 3 = some ([2], [2], [0,3]) := by decide

private def point : Index (line.shape 1) := fun i => ⟨0, by by_cases h : i = 0 <;> simp [Frame.shape, line, h]⟩
-- Global [3,4) has local shift one in the second block. Shift zero changes the value.
example :
    line.slice (concatenate operands) 3 1 (by decide) point ≠
    line.slice (segment 2 20).values 0 1 (by decide) point := by decide

#print axioms subrange
#print axioms unary
#print axioms exactPiece
end RevisedBenchmark.ConcatScan
