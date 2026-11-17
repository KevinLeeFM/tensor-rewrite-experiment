module
public import Goal
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeStatic
open TensorRewrite.Pilot.SliceShape
/-- The frozen unit-stride validity goal. -/
theorem validity : Goal := by
  intro extent middle output inner outer hi ho his hos
  rcases hi with ⟨hi0, hil, hie, hip, him, hic⟩
  rcases ho with ⟨ho0, hol, hoe, hop, hoo, hoc⟩
  simp [Axis.elementCount, his] at hic
  simp [Axis.elementCount, hos] at hoc
  simp only [IsWellFormed, Axis.elementCount]
  simp
  omega
#print axioms validity
end RevisedBenchmark.SliceComposeStatic
