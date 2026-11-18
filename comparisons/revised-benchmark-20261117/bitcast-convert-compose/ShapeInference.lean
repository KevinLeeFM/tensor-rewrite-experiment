import Std

set_option autoImplicit false

namespace RevisedBenchmark.BitcastConvertCompose

/-- Relevant static-shape portion of XLA InferBitcastConvertShape.
Widths are positive storage widths; complex/array admission is fixed to U types.
A narrower output appends the ratio as a minor dimension. A wider output removes
its static final dimension only when that extent is exactly the ratio. -/
def inferBitcastConvertShape (dims : List Nat) (inputWidth outputWidth : Nat) :
    Option (List Nat) := Id.run do
  if inputWidth == 0 || outputWidth == 0 then
    return none
  let larger := max inputWidth outputWidth
  let smaller := min inputWidth outputWidth
  if larger % smaller != 0 then
    return none
  let ratio := larger / smaller
  if inputWidth > outputWidth then
    return some (dims ++ [ratio])
  if inputWidth < outputWidth then
    match dims.getLast? with
    | none => return none
    | some last =>
      if last != ratio then return none
      return some (dims.take (dims.length - 1))
  return some dims

/-- The nested source chain is shape-inferred, but its direct replacement shape
is different and therefore fails the frozen shape-verifier condition. -/
theorem nestedShapeInference :
    inferBitcastConvertShape [] 32 16 = some [2] ∧
    inferBitcastConvertShape [2] 16 8 = some [2, 2] ∧
    inferBitcastConvertShape [] 32 8 = some [4] ∧
    inferBitcastConvertShape [] 32 8 ≠ some [2, 2] := by
  decide

/-- Wrong-ratio widening fails the same source shape condition. -/
theorem wrongWideningExtentRejected :
    inferBitcastConvertShape [3] 16 32 = none := by
  decide

end RevisedBenchmark.BitcastConvertCompose

#print axioms RevisedBenchmark.BitcastConvertCompose.nestedShapeInference
#print axioms RevisedBenchmark.BitcastConvertCompose.wrongWideningExtentRejected
