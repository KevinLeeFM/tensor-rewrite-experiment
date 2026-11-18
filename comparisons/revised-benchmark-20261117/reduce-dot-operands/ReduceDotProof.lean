import ReduceDotSpec

set_option autoImplicit false

namespace RevisedBenchmark.ReduceDotOperands

/-- Left parameter has ones at (0,1) on every free-axis slice. -/
def left (_i : Fin 3) (p q : Fin 2) : Int := if p = 0 ∧ q = 1 then 1 else 0

/-- Right parameter has ones at the transposed location (1,0). -/
def right (_j : Fin 3) (p q : Fin 2) : Int := if p = 1 ∧ q = 0 then 1 else 0

/-- The crossed-pair dot is one at all nine output positions; after reducing
operands, the two nonzero locations fail to coincide in the parallel-pair dot. -/
theorem verified : Case := by
  intro law
  have feasible : admitted 3 3 := by unfold admitted; decide
  have different : original left right ≠ replacement left right := by decide
  exact different (law 3 3 feasible left right)

#print axioms verified

end RevisedBenchmark.ReduceDotOperands
