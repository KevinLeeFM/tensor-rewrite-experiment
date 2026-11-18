module
public import AdjacentSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.AdjacentScan

private theorem pairLaw (a b c : Block) (h : merge a b = some c) :
    width c = width a + width b ∧
    ∀ (α : Type) (src other : Reader α) (outer post : List Nat),
      row src other outer post c = row src other outer post a ++ row src other outer post b := by
  cases a <;> cases b <;> simp only [merge] at h
  case slice.slice k s w l t v =>
    split at h
    next hits =>
      obtain ⟨rfl,rfl⟩ := hits
      cases h
      have ends : s+w+v-s = w+v := by omega
      refine ⟨by simp [width, ends], ?_⟩
      intro α src other outer post
      simp only [row, ends, ← List.flatMap_append, List.range'_append_1]
    next => contradiction
  all_goals contradiction

private theorem runWidth (a : Block) (bs : List Block) :
    ((run a bs).map width).sum = width a + (bs.map width).sum := by
  induction bs generalizing a with
  | nil => simp [run]
  | cons b t ih =>
    simp only [run]
    split
    next c h => simp [ih, (pairLaw a b c h).1, Nat.add_assoc]
    next h => simp [ih]

private theorem runRow {α : Type} (src other : Reader α) (outer post : List Nat)
    (a : Block) (bs : List Block) :
    (run a bs).flatMap (row src other outer post) =
      row src other outer post a ++ bs.flatMap (row src other outer post) := by
  induction bs generalizing a with
  | nil => simp [run]
  | cons b t ih =>
    simp only [run]
    split
    next c h => simp [ih, (pairLaw a b c h).2 α src other outer post, List.append_assoc]
    next h => simp [ih]

/-- No scanner guard matches the boundary with the preceding block. -/
def stopped (prev : Option Block) (b : Block) : Prop :=
  ∀ p, prev = some p → merge p b = none

/-- Every adjacent output boundary fails the actual merge guard. -/
def separated : Option Block → List Block → Prop
  | _, [] => True
  | prev, b::t => stopped prev b ∧ separated (some b) t

private theorem extendRight (prev : Option Block) (a b c : Block)
    (joined : merge a b = some c) (before : stopped prev a) : stopped prev c := by
  intro p hp
  have old := before p hp
  cases a <;> cases b <;> simp only [merge] at joined
  case slice.slice k s w l t v =>
    split at joined
    next ok =>
      cases joined
      cases p with
      | slice => simpa [merge] using old
      | «opaque» => rfl
    next => contradiction
  all_goals contradiction

private theorem runSeparated (a : Block) (bs : List Block) (prev : Option Block)
    (h : stopped prev a) : separated prev (run a bs) := by
  induction bs generalizing a prev with
  | nil => exact ⟨h, trivial⟩
  | cons b t ih =>
    simp only [run]
    split
    next c hit => exact ih c prev (extendRight _ _ _ _ hit h)
    next missed =>
      refine ⟨h, ih b (some a) ?_⟩
      intro p hp
      cases hp
      exact missed

theorem maximal (bs : List Block) : separated none (scan bs) := by
  cases bs with
  | nil => trivial
  | cons a t => exact runSeparated a t none (by intro p hp; contradiction)

/-- Derived directly by induction over the actual left-to-right scanner. -/
theorem verified : Goal := by
  intro bs
  cases bs with
  | nil => simp [scan]
  | cons a t => simp [scan, runWidth, packed, runRow]
#print axioms maximal
#print axioms verified
end RevisedBenchmark.AdjacentScan
