module
public import EffectiveGatherSpec
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.EffectiveGather
open TensorRewrite.Pilot

/-- Once a bounded input coordinate has been computed, each of its components
is forced. This applies both to Gather and to the row-major scalar reshape. -/
theorem verified : Case := by
  constructor
  · intro t dst α x g
    funext o
    apply congrArg x
    funext a
    exact a.elim0
  · intro k t s unit dst α x g
    funext o
    apply congrArg x
    funext a
    apply Fin.ext
    have unique (j : Fin (s a)) : j.val = 0 := by
      have h := j.isLt
      have ha := unit a
      omega
    exact (unique _).trans (unique _).symm

example : Case := verified
#print axioms verified
end RevisedBenchmark.EffectiveGather
