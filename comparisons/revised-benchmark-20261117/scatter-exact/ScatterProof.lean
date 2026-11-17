module
public import ScatterSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.ScatterExact
open TensorRewrite.Pilot.ReducerIndex.ScatterRoles

private theorem fixed {w : Nat} (x y : BitVec w) (h : x + y = y) : x = 0 :=
  (BitVec.add_left_inj y).mp (h.trans (BitVec.zero_add y).symm)

private theorem direct {n w : Nat} (a b : Parameter) (extra base : Fin n → BitVec w)
    (t : Fin n) (u : BitVec w) :
    before a b extra base t u = after a b extra base t u ↔ a ≠ b ∨ extra t = 0 := by
  constructor
  · intro eq
    by_cases diff : a ≠ b
    · exact Or.inl diff
    · have same : a = b := by simpa using diff
      subst b
      right
      have h := congrFun eq t
      cases a with
      | current =>
        simp [before, after, scatter, combine, parameterValue] at h
        apply fixed (extra t) (extra t + (base t + base t))
        calc
          _ = (extra t + base t) + (extra t + base t) := by ac_rfl
          _ = _ := h.symm
      | update =>
        exact fixed _ (u + u) (by simpa [before, after, scatter, combine, parameterValue] using h)
  · rintro (distinct | zero)
    · exact distinct_parameters_preserve a b distinct extra base t u
    · funext i
      by_cases same : i = t
      · subst i
        simp [before, after, scatter, zero, BitVec.zero_add]
      · simp [before, after, scatter, same]

theorem correct : Goal := by
  intro n w left a b extra base t u
  cases left with
  | false => exact direct a b extra base t u
  | true =>
    have lhs : original true a b extra base t u = before a b extra base t u := by
      funext i; exact BitVec.add_comm _ _
    have rhs : replacement true a b extra base t u = after a b extra base t u := by
      apply congrArg (fun data => scatter a b data t u)
      funext i; exact BitVec.add_comm _ _
    rw [lhs, rhs]
    exact direct a b extra base t u
#print axioms correct
end RevisedBenchmark.ScatterExact
