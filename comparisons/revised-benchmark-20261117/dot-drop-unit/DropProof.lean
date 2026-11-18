import DropSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotDropUnit

private theorem expanded (s : Shape) :
    (grid (compact s)).map (expand s) = grid s := by
  induction s with
  | nil => rfl
  | cons n ns ih =>
    by_cases h : n = 1
    · subst n
      simpa [compact, grid, expand, List.map_map, Function.comp_def] using
        congrArg (List.map (0 :: ·)) ih
    · have hc : compact (n :: ns) = n :: compact ns := by simp [compact, h]
      rw [hc, grid, grid, List.map_flatMap]
      apply congrArg (List.flatMap · (List.range n))
      funext i
      simpa [List.map_map, Function.comp_def, expand, h] using
        congrArg (List.map (i :: ·)) ih

private theorem paired : descriptorCase := by
  intro l r ps legal
  induction ps with
  | nil => rfl
  | cons p ps ih =>
    obtain ⟨n, hl, hr⟩ := legal p (by simp)
    have tail := ih (fun q h => legal q (by simp [h]))
    rcases p with ⟨i,j⟩
    by_cases hu : n = 1
    · subst n
      simpa [remap, hl, hr] using tail
    · simpa [remap, hl, hr, hu] using congrArg
        (List.cons ((compact (l.take i)).length, (compact (r.take j)).length)) tail

private theorem sameData (b l r k : Shape) (a z : Operand) :
    dotData b l r k a z = dotData (compact b) (compact l) (compact r) (compact k)
      (pull b l k a) (pull b r k z) := by
  unfold dotData
  conv => lhs; rw [← expanded b, ← expanded l, ← expanded r, ← expanded k]
  simp [List.flatMap_map, List.map_map, Function.comp_def, pull]

theorem verified : Case := by
  refine ⟨paired, ?_⟩
  intro b l r k a z _
  unfold original replacement
  dsimp only
  split <;> simp_all [sameData b l r k a z]
end RevisedBenchmark.DotDropUnit
