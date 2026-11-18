import FullFastSpec
set_option autoImplicit false
namespace RevisedBenchmark.WindowFullF32
/-- At 2^24 the unit in the last place is two. Two separately added ones tie
back to the same even stored F32; both accumulate exactly in the double chunk. -/
theorem refuted : ¬ Goal := by
  intro all
  have clash := all [16777216,1,1] (by decide) (by decide)
    (by intro n h; simp at h; omega) 0
  revert clash
  decide
#print axioms refuted
end RevisedBenchmark.WindowFullF32
