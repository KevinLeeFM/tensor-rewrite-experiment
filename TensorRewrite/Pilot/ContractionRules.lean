module

public import TensorRewrite.Pilot.ContractionLemmas
public import TensorRewrite.Pilot.ReshapeLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Contraction

variable {batch left right contracting : Nat} {L R Acc Result : Type}
  (plan : Plan batch left right contracting) (add : Acc → Acc → Acc) (zero : Acc)
  (multiply : L → R → Acc) (finish : Acc → Result)
  (lhs : Tensor plan.lhsShape L) (rhs : Tensor plan.rhsShape R)

/-- An empty contraction returns the finished initializer at every output coordinate. -/
theorem dot_empty_contract (empty : LinearIndex.elementCount plan.contractShape = 0) :
    dotTensor plan add zero multiply finish lhs rhs = Tensor.constant (finish zero) := by
  funext output
  have lengthZero := (terms_length plan multiply lhs rhs output).trans empty
  have noTerms := List.eq_nil_of_length_eq_zero lengthZero
  change finish ((terms plan multiply lhs rhs output).foldl add zero) = finish zero
  rw [noTerms]
  rfl

/-- An empty result is equal to the zero broadcast, independently of scalar arithmetic. -/
theorem dot_empty_output (empty : LinearIndex.elementCount plan.outputShape = 0) :
    dotTensor plan add zero multiply finish lhs rhs = Tensor.constant (finish zero) :=
  Reshape.tensor_eq_of_empty empty _ _

/-- Empty lhs implies the zero broadcast, including empty-output and empty-fiber cases. -/
theorem dot_empty_lhs (empty : LinearIndex.elementCount plan.lhsShape = 0) :
    dotTensor plan add zero multiply finish lhs rhs = Tensor.constant (finish zero) := by
  funext output
  have fiberEmpty := contract_count_zero_of_lhs_empty plan output empty
  exact congrFun (dot_empty_contract plan add zero multiply finish lhs rhs fiberEmpty) output

/-- Empty rhs likewise suffices without assuming an identity law or nonzero extents. -/
theorem dot_empty_rhs (empty : LinearIndex.elementCount plan.rhsShape = 0) :
    dotTensor plan add zero multiply finish lhs rhs = Tensor.constant (finish zero) := by
  funext output
  have fiberEmpty := contract_count_zero_of_rhs_empty plan output empty
  exact congrFun (dot_empty_contract plan add zero multiply finish lhs rhs fiberEmpty) output

/-- The initializer may be removed when it is invisible after the actual finish conversion. -/
theorem dot_no_contract_of_finish_identity {batch left right : Nat}
    (plan : Plan batch left right 0) (add : Acc → Acc → Acc) (zero : Acc)
    (multiply : L → R → Acc) (finish : Acc → Result)
    (identityAfterFinish : ∀ value, finish (add zero value) = finish value)
    (lhs : Tensor plan.lhsShape L) (rhs : Tensor plan.rhsShape R) :
    dotTensor plan add zero multiply finish lhs rhs = outerTensor plan multiply finish lhs rhs := by
  funext output
  simp only [dotTensor, terms_no_contract, List.foldl_cons, List.foldl_nil,
    identityAfterFinish, outerTensor]

/-- A left-identity initializer suffices without requiring an injective finish conversion. -/
theorem dot_no_contract {batch left right : Nat} (plan : Plan batch left right 0)
    (add : Acc → Acc → Acc) (zero : Acc) (multiply : L → R → Acc) (finish : Acc → Result)
    (leftIdentity : ∀ value, add zero value = value)
    (lhs : Tensor plan.lhsShape L) (rhs : Tensor plan.rhsShape R) :
    dotTensor plan add zero multiply finish lhs rhs = outerTensor plan multiply finish lhs rhs :=
  dot_no_contract_of_finish_identity plan add zero multiply finish
    (fun value => congrArg finish (leftIdentity value)) lhs rhs

end TensorRewrite.Pilot.Contraction
