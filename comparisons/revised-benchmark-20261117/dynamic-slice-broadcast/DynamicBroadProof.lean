import DynamicBroadSpec
set_option autoImplicit false
namespace RevisedBenchmark.DynamicBroad
open TensorRewrite.Pilot

theorem verified : Case := by
  constructor
  · intro m n p
    have h (a) : widths p a ≤ p.input a := by rw [p.matchExtent]; exact p.fits _
    refine ⟨h, ?_⟩
    intro α x starts
    funext q
    apply congrArg x
    funext a
    apply Fin.ext
    simp [GatherHoist.atStart,p.matchExtent]
  · intro n p α x starts
    funext q
    apply congrArg x
    funext a
    exact a.elim0
#print axioms verified
end RevisedBenchmark.DynamicBroad
