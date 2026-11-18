import TupleExpandProof
namespace RevisedBenchmark.TupleExpand
abbrev Payload := Sum (List Nat) Bool
def v : Lit Payload := .tuple 2 fun i =>
  if i.val=0 then .tuple 2 fun j => if j.val=0 then .atom (.inl [42,7]) else .tuple 0 Fin.elim0
  else .atom (.inr false)
example : expressionAt [0,0] (expand v) = some (.atom (.inl [42,7])) := by decide
example : expressionAt [0,1] (expand v) = some (.arity 0) ∧ expressionAt [1,0] (expand v) = none := by decide
example : expressionAt [1] (expand v) = some (.atom (.inr false)) ∧ expressionAt [2] (expand v) = none := by decide
example : expressionAt [0] (expand v) ≠ literalAt [1] v := by decide
end RevisedBenchmark.TupleExpand
