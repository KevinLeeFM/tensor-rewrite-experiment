import TupleExpandSpec
set_option autoImplicit false
namespace RevisedBenchmark.TupleExpand
private theorem paths {α : Type} (path : List Nat) (v : Lit α) :
    literalAt path v = expressionAt path (expand v) := by
  induction path generalizing v with
  | nil => cases v <;> simp [literalAt,expressionAt,expand]
  | cons k ks ih =>
    cases v with
    | atom => rfl
    | tuple n c =>
      by_cases h : k < n
      · simpa [literalAt,expressionAt,expand,List.getElem?_ofFn,h] using ih (c ⟨k,h⟩)
      · simp [literalAt,expressionAt,expand,h]
theorem verified : Case := fun _ _ _ => paths _ _
#print axioms verified
end RevisedBenchmark.TupleExpand
