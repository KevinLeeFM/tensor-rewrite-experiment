import SliceDotSpec
set_option autoImplicit false
namespace RevisedBenchmark.SliceDot
private theorem countWhole (n : Nat) : width (whole n) = n := by simp [width, whole]

private theorem shapeEq {b f k : Nat} (axes : List (Axis b f k)) (offset : Nat)
    (ks : Fin k → Nat) (s : Nat → Slice) :
    projectedShape axes offset ks s = axes.map (extent offset (fun j => width (s j)) ks) := by
  apply List.map_congr_left
  intro a _
  cases a <;> simp [project, extent, countWhole]

private theorem operandEq {b f k : Nat} (axes : List (Axis b f k)) (offset : Nat)
    (out : Nat → Nat) (ks : Fin k → Nat) (s : Nat → Slice) (q : Nat → Nat)
    (x : List Nat → Int) (t : List Nat) :
    originalOperand axes offset s q x t = replacementOperand axes offset out ks s q x t := by
  unfold originalOperand replacementOperand
  dsimp only
  split <;> rename_i flag
  · congr 1
    apply List.map_congr_left
    intro a _
    cases a <;> simp [readAt, project, atCoord, whole]
  · congr 1
    apply List.map_congr_left
    intro a ha
    have eq : project offset ks s a = whole (extent offset out ks a) := by
      apply Classical.byContradiction
      intro h
      exact flag (List.any_eq_true.mpr ⟨a, ha, by simpa using h⟩)
    cases a with
    | contract i => rfl
    | batch i | free i =>
      simp only [project, extent] at eq
      simp [readAt, eq, whole, atCoord]

/-- An admitted output index samples a real source position. -/
theorem sampleInBounds (s : Slice) (n i : Nat) (hs : s.start ≤ s.limit)
    (hl : s.limit ≤ n) (hp : 0 < s.stride) (hi : i < width s) : atCoord s i < n := by
  have h := (Nat.le_div_iff_mul_le hp).mp (show i+1 ≤
    (s.limit - s.start + s.stride - 1) / s.stride from hi)
  simp only [Nat.add_mul, Nat.one_mul] at h
  unfold atCoord
  omega

/-- Every full grid point has the required rank and a strictly bounded index
on every paired contracting axis. Thus the out-of-rank defaults are unreachable. -/
theorem gridInBounds (ns t : List Nat) (ht : t ∈ grid ns) : 
    t.length = ns.length ∧ ∀ j, j < ns.length → t[j]?.getD 0 < ns[j]?.getD 0 := by
  induction ns generalizing t with
  | nil =>
    simp only [grid, List.mem_singleton] at ht
    subst t
    simp
  | cons n ns ih =>
    obtain ⟨i, hi, h⟩ := List.mem_flatMap.mp ht
    obtain ⟨p, hp, rfl⟩ := List.mem_map.mp h
    obtain ⟨hlen, bounds⟩ := ih p hp
    refine ⟨by simp [hlen], ?_⟩
    intro j hj
    cases j with
    | zero => exact List.mem_range.mp hi
    | succ j => exact bounds j (by simpa using hj)

theorem verified : Case := by
  intro b l r k lhs rhs out ks s _ _ _
  refine ⟨shapeEq .., shapeEq .., ?_⟩
  intro x y q _
  simp only [project, countWhole]
  congr 1 <;> funext t <;> apply operandEq
example : Case := verified
#print axioms verified
end RevisedBenchmark.SliceDot
