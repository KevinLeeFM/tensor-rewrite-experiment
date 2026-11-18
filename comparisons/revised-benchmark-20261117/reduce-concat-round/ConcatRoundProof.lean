import ConcatRoundSpec
set_option autoImplicit false
namespace RevisedBenchmark.ReduceConcat

theorem witness :
    original 16777216 0 1 1 = 16777216 ∧
    replacement 16777216 0 1 1 = 16777218 := by decide

theorem refuted : ¬ StrictCase := by
  intro h
  have eq := h 16777216 0 1 1 (by decide) (by decide) (by decide) (by decide)
  rw [witness.1, witness.2] at eq
  exact (by decide : (16777216 : Nat) ≠ 16777218) eq

end RevisedBenchmark.ReduceConcat
