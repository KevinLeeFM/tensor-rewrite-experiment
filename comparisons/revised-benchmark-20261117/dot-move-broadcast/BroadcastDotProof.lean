import BroadcastDotSpec

set_option autoImplicit false

namespace RevisedBenchmark.BroadcastDot

/-- Select partner contraction coordinate zero. -/
def vector (k : Fin 2) : Int := if k.val = 0 then 1 else 0

/-- Nonzero entries occupy the off-diagonal (contracting=0, free=1). -/
def partner (i : Fin 4) (k j : Fin 2) : Int :=
  if k.val = 0 ∧ j.val = 1 then Int.ofNat (i.val + 1) else 0

/-- Both orientations violate the frozen guarded rewrite on the same shapes. -/
theorem verified : Case := by
  intro fromRight h
  have fit : admitted 4 2 := by unfold admitted; decide
  have eq := h 4 2 fit vector partner 1
  cases fromRight <;> revert eq <;> decide

#print axioms verified
end RevisedBenchmark.BroadcastDot
