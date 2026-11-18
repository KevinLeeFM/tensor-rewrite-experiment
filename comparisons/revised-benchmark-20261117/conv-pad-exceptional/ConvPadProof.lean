import ConvPadSpec

set_option autoImplicit false
namespace RevisedBenchmark.ConvPad

/-- A materialized leading zero is multiplied by infinity; a skipped tap never is. -/
theorem inputRefuted : ¬ InputLaw := by
  intro h
  exact (by decide : conv [.zero,.posInf] [.posInf,.posInf] 0 0 1 ≠
    conv [.posInf] [.posInf,.posInf] 1 0 1)
    (h [.posInf] [.posInf,.posInf] 1 0 (by decide) (by decide))

/-- A materialized zero inside the filter is multiplied by infinity at an in-bounds input. -/
theorem filterRefuted : ¬ FilterLaw := by
  intro h
  exact (by decide : conv [.posInf,.posInf,.posInf] (interior 1 [.posInf,.posInf]) 0 0 1 ≠
    conv [.posInf,.posInf,.posInf] [.posInf,.posInf] 0 0 2)
    (h [.posInf,.posInf,.posInf] [.posInf,.posInf] 1 (by decide) (by decide))

#print axioms inputRefuted
#print axioms filterRefuted
end RevisedBenchmark.ConvPad
