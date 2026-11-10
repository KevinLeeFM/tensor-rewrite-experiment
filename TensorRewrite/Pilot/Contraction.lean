module

public import TensorRewrite.Pilot.Permutation
public import TensorRewrite.Pilot.LinearIndex

/-! Ordered logical contraction with explicit batch/free/contract axis groups.
Operand permutations are bijections, and all coordinate maps are constructed
from the groups. Precision, scalar conversions and finish are explicit inputs. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.Contraction

/-- Concatenate shape axes in left-then-right order. -/
def appendShape {left right : Nat} (lhs : Shape left) (rhs : Shape right) : Shape (left + right) :=
  Fin.addCases lhs rhs

/-- Concatenate bounded coordinates using precisely the shape concatenation. -/
def appendIndex {left right : Nat} {lhs : Shape left} {rhs : Shape right}
    (first : Index lhs) (second : Index rhs) : Index (appendShape lhs rhs) :=
  Fin.addCases
    (fun axis => Fin.cast (by simp [appendShape]) (first axis))
    (fun axis => Fin.cast (by simp [appendShape]) (second axis))

/-- Project the initial coordinate block. -/
def firstIndex {left right : Nat} {lhs : Shape left} {rhs : Shape right}
    (index : Index (appendShape lhs rhs)) : Index lhs :=
  fun axis => Fin.cast (by simp [appendShape]) (index (Fin.castAdd right axis))

/-- Project the final coordinate block. -/
def secondIndex {left right : Nat} {lhs : Shape left} {rhs : Shape right}
    (index : Index (appendShape lhs rhs)) : Index rhs :=
  fun axis => Fin.cast (by simp [appendShape]) (index (Fin.natAdd left axis))

/-- Axis groups and the actual operand order relative to canonical batch/free/contract blocks. -/
structure Plan (batch left right contracting : Nat) where
  /-- Paired batch extents in result-prefix order. -/
  batchShape : Shape batch
  /-- Lhs free extents in result order. -/
  leftShape : Shape left
  /-- Rhs free extents following the lhs result block. -/
  rightShape : Shape right
  /-- Shared contracted extents in the selected accumulation order. -/
  contractShape : Shape contracting
  /-- Canonical lhs axes mapped bijectively to original operand axes. -/
  leftOrder : AxisPermutation (batch + (left + contracting))
  /-- Canonical rhs axes mapped bijectively to original operand axes. -/
  rightOrder : AxisPermutation (batch + (right + contracting))

/-- Result dimensions are batch, lhs free, then rhs free, in that order. -/
def Plan.outputShape {batch left right contracting : Nat}
    (plan : Plan batch left right contracting) : Shape (batch + (left + right)) :=
  appendShape plan.batchShape (appendShape plan.leftShape plan.rightShape)

/-- Original lhs shape, obtained from its full canonical axis permutation. -/
def Plan.lhsShape {batch left right contracting : Nat} (plan : Plan batch left right contracting) :
    Shape (batch + (left + contracting)) := fun axis =>
  appendShape plan.batchShape (appendShape plan.leftShape plan.contractShape)
    (plan.leftOrder.inputToOutput axis)

/-- Original rhs shape, with the paired batch/contract extents shared explicitly. -/
def Plan.rhsShape {batch left right contracting : Nat} (plan : Plan batch left right contracting) :
    Shape (batch + (right + contracting)) := fun axis =>
  appendShape plan.batchShape (appendShape plan.rightShape plan.contractShape)
    (plan.rightOrder.inputToOutput axis)

/-- Reconstruct the original lhs coordinate from output and contraction coordinates. -/
def Plan.lhsIndex {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    (output : Index plan.outputShape) (contract : Index plan.contractShape) : Index plan.lhsShape :=
  let batchIndex := firstIndex output
  let freeIndex := firstIndex (secondIndex output)
  let canonical := appendIndex batchIndex (appendIndex freeIndex contract)
  fun axis => canonical (plan.leftOrder.inputToOutput axis)

/-- Reconstruct the original rhs coordinate with the same paired batch/contract values. -/
def Plan.rhsIndex {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    (output : Index plan.outputShape) (contract : Index plan.contractShape) : Index plan.rhsShape :=
  let batchIndex := firstIndex output
  let freeIndex := secondIndex (secondIndex output)
  let canonical := appendIndex batchIndex (appendIndex freeIndex contract)
  fun axis => canonical (plan.rightOrder.inputToOutput axis)

/-- Products in dim0-major contraction-coordinate order; no reassociation is assumed. -/
def terms {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    {L R Acc : Type} (multiply : L → R → Acc) (lhs : Tensor plan.lhsShape L)
    (rhs : Tensor plan.rhsShape R) (output : Index plan.outputShape) : List Acc :=
  (List.finRange (LinearIndex.elementCount plan.contractShape)).map fun position =>
    let contract := LinearIndex.delinearize plan.contractShape position
    multiply (lhs (plan.lhsIndex output contract)) (rhs (plan.rhsIndex output contract))

/-- Ordered fold from the actual zero/initializer, followed by the explicit output conversion. -/
def dotTensor {batch left right contracting : Nat} (plan : Plan batch left right contracting)
    {L R Acc Result : Type} (add : Acc → Acc → Acc) (zero : Acc) (multiply : L → R → Acc)
    (finish : Acc → Result) (lhs : Tensor plan.lhsShape L) (rhs : Tensor plan.rhsShape R) :
    Tensor plan.outputShape Result := fun output =>
  finish ((terms plan multiply lhs rhs output).foldl add zero)

/-- Product/broadcast replacement for a Dot with no contracting axes. -/
def outerTensor {batch left right : Nat} (plan : Plan batch left right 0)
    {L R Acc Result : Type} (multiply : L → R → Acc) (finish : Acc → Result)
    (lhs : Tensor plan.lhsShape L) (rhs : Tensor plan.rhsShape R) :
    Tensor plan.outputShape Result :=
  fun output =>
    let contract : Index plan.contractShape := fun axis => Fin.elim0 axis
    finish (multiply (lhs (plan.lhsIndex output contract)) (rhs (plan.rhsIndex output contract)))

end TensorRewrite.Pilot.Contraction
