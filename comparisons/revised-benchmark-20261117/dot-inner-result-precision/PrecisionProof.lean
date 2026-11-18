import PrecisionSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotResult

/-- A single nonzero entry prevents accumulation order from changing the value. -/
def single (v : Nat) : Data := fun i j => if i = 0 ∧ j = 0 then v else 0

theorem refuted : (¬ Goal true) ∧ (¬ Goal false) := by
  constructor
  · intro h
    have bad := h 8 2 8 2 (by decide) (by decide) (by decide)
      (single 129) (single 129) (single 1) 0 0 16640 16641 (by decide) (by decide)
    exact (by decide : 16640 ≠ 16641) bad
  · intro h
    have bad := h 2 8 2 8 (by decide) (by decide) (by decide)
      (single 1) (single 129) (single 129) 0 0 16640 16641 (by decide) (by decide)
    exact (by decide : 16640 ≠ 16641) bad
#print axioms refuted
end RevisedBenchmark.DotResult
