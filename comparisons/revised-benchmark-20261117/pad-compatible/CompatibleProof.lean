module
public import CompatibleSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.CompatiblePad
open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.PaperComparison.SignedPad

/-- Equal input/output extents and zero edges leave no room for a hole
    between two distinct bounded input coordinates. -/
theorem correct : Goal := by
  intro r s p edges α fill xs
  funext j
  have samples : selected p j = some j := by
    apply (LatticeIndex.assemble_eq_some_iff _ _).mpr
    intro d
    apply (sample_some _ _ _ _ _).mpr
    obtain ⟨lo, hi⟩ := edges d
    have shape := p.shape d
    simp only [extent, lo, hi, Int.add_zero] at shape
    have prod : max 0 ((s d : Int)-1) * (p.interior d : Int) = 0 := by omega
    rcases Int.mul_eq_zero.mp prod with tiny | noHoles
    · have bound := (j d).isLt
      have zero : (j d).val = 0 := by omega
      simp [lo, zero]
    · simp [lo, noHoles]
  simp [tensor, samples]
#print axioms correct
end RevisedBenchmark.CompatiblePad
