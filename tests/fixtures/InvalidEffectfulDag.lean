import TensorRewrite

open TensorRewrite.Pilot.Dag

-- Equal return values do not justify dropping an observable event.
example : (Outcome.mk (.ok false) [1] : Outcome Bool (List Nat) String) =
    ⟨.ok false, []⟩ := by
  rfl
