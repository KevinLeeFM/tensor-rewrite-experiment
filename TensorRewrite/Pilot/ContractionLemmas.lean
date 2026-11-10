module

public import TensorRewrite.Pilot.Contraction
public import TensorRewrite.Pilot.LinearIndexLemmas

public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Contraction

/-- Projecting the first concatenated coordinate block recovers it exactly. -/
theorem firstIndex_appendIndex {left right : Nat} {lhs : Shape left} {rhs : Shape right}
    (first : Index lhs) (second : Index rhs) : firstIndex (appendIndex first second) = first := by
  funext axis
  apply Fin.ext
  simp [firstIndex, appendIndex]

/-- Projecting the second concatenated coordinate block recovers it exactly. -/
theorem secondIndex_appendIndex {left right : Nat} {lhs : Shape left} {rhs : Shape right}
    (first : Index lhs) (second : Index rhs) : secondIndex (appendIndex first second) = second := by
  funext axis
  apply Fin.ext
  simp [secondIndex, appendIndex]

/-- Contraction enumeration has exactly the product of contracted extents. -/
theorem terms_length {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    {L R Acc : Type} (multiply : L → R → Acc) (lhs : Tensor plan.lhsShape L)
    (rhs : Tensor plan.rhsShape R) (output : Index plan.outputShape) :
    (terms plan multiply lhs rhs output).length = LinearIndex.elementCount plan.contractShape := by
  simp only [terms, List.length_map, List.length_finRange]

/-- No contracting axes means one product, not an empty accumulation. -/
theorem terms_no_contract {batch left right : Nat} (plan : Plan batch left right 0)
    {L R Acc : Type} (multiply : L → R → Acc) (lhs : Tensor plan.lhsShape L)
    (rhs : Tensor plan.rhsShape R) (output : Index plan.outputShape) :
    terms plan multiply lhs rhs output =
      [multiply (lhs (plan.lhsIndex output (fun axis => Fin.elim0 axis)))
        (rhs (plan.rhsIndex output (fun axis => Fin.elim0 axis)))] := by
  rfl

/-- If an output coordinate exists but lhs is empty, the contraction fiber must be empty. -/
theorem contract_count_zero_of_lhs_empty {batch left right contracting : Nat}
    (plan : Plan batch left right contracting) (output : Index plan.outputShape)
    (empty : LinearIndex.elementCount plan.lhsShape = 0) :
    LinearIndex.elementCount plan.contractShape = 0 := by
  by_cases zero : LinearIndex.elementCount plan.contractShape = 0
  · exact zero
  have positive := Nat.pos_of_ne_zero zero
  let contract := LinearIndex.delinearize plan.contractShape ⟨0, positive⟩
  have impossible := (LinearIndex.linearize plan.lhsShape (plan.lhsIndex output contract)).isLt
  omega

/-- The same argument applies to an empty rhs, without a scalar arithmetic assumption. -/
theorem contract_count_zero_of_rhs_empty {batch left right contracting : Nat}
    (plan : Plan batch left right contracting) (output : Index plan.outputShape)
    (empty : LinearIndex.elementCount plan.rhsShape = 0) :
    LinearIndex.elementCount plan.contractShape = 0 := by
  by_cases zero : LinearIndex.elementCount plan.contractShape = 0
  · exact zero
  have positive := Nat.pos_of_ne_zero zero
  let contract := LinearIndex.delinearize plan.contractShape ⟨0, positive⟩
  have impossible := (LinearIndex.linearize plan.rhsShape (plan.rhsIndex output contract)).isLt
  omega

end TensorRewrite.Pilot.Contraction
