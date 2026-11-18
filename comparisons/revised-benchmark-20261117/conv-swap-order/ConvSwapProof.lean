import ConvSwapSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvSwapOrder

def sample (i : Fin 3) : Nat := if i.val = 2 then 16777216 else 1
-- Slot 3 is intentionally different and is outside the old spatial domain.
def filter (j : Fin 4) : Nat := if j.val = 3 then 7 else 1

theorem witness : original sample filter = 16777218 ∧ rewritten sample filter = 16777216 := by decide
theorem refuted : ¬ StrictCase := by
  intro h
  have e := h sample filter (by decide) (by decide)
  rw [witness.1,witness.2] at e
  exact (by decide : (16777218 : Nat) ≠ 16777216) e
#print axioms refuted
#print axioms witness
end RevisedBenchmark.ConvSwapOrder
