module
public import OutsideReuse
public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceOfPad
open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.PaperComparison.SignedPad

theorem inside : Inside := by
  intro r s m o p a v guarded
  have w (d : Fin r) : SliceShape.IsWellFormed (s d) (o d) (shifted p a d) := by
    obtain ⟨lo, hi, gap, stride⟩ := guarded d
    obtain ⟨_, order, _, _, good, count⟩ := v d
    have eq := p.shape d
    simp [extent, gap] at eq
    simp [SliceShape.Axis.elementCount, stride] at count
    simp [shifted, SliceShape.IsWellFormed, SliceShape.Axis.elementCount, stride]
    omega
  refine ⟨w, ?_⟩
  intro α fill xs j
  have sel : selected p (IndexMaps.sliceIndex a v j) = some (IndexMaps.sliceIndex (shifted p a) w j) := by
    apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
    intro d
    apply (sample_some ..).mpr
    obtain ⟨_, _, gap, stride⟩ := guarded d
    rw [IndexMaps.sliceIndex_val, IndexMaps.sliceIndex_val]
    simp [shifted, gap, stride]
    omega
  simp [tensor, sel]

theorem undo : Undo := by
  intro r s m p a v guarded α fill xs j
  have sel : selected p (IndexMaps.sliceIndex a v j) = some j := by
    apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
    intro d
    apply (sample_some ..).mpr
    obtain ⟨start, stride⟩ := guarded d
    have step : (a d).stride = (p.interior d : Int) + 1 := by omega
    rw [IndexMaps.sliceIndex_val, start, step, Int.mul_comm]
  simp [tensor, sel]

theorem paddingOnly : PaddingOnly := by
  intro r s m o p a v h α fill xs j
  obtain ⟨d, outside⟩ := h
  apply congrFun (slice_outside p a v d ?_ fill xs) j
  rcases outside with left | right
  · exact Or.inl left
  · right
    have shape := p.shape d
    by_cases z : s d = 0
    · simp [extent, z, show max (0 : Int) (-1) = 0 by decide] at shape ⊢
      omega
    · have same : max 0 ((s d : Int)-1) = ((s d : Int)-1) := by omega
      simp only [extent, same] at shape
      omega
#print axioms inside
#print axioms undo
#print axioms paddingOnly
end RevisedBenchmark.SliceOfPad
