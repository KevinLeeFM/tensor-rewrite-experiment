import TensorRewrite.Theory.ReductionCounterexamples

set_option autoImplicit false

open TensorRewrite.Pilot TensorRewrite.Pilot.Reduction
open TensorRewrite.Theory.ReductionFiber

private def profiles : List (String × Plan) := [
  ("scalar", .scalar),
  ("all_kept", .keep 2 (.keep 3 .scalar)),
  ("all_reduced", .reduce 2 (.reduce 3 .scalar)),
  ("mixed", .keep 2 (.reduce 3 (.keep 2 (.reduce 2 .scalar)))),
  ("leading_reduced", .reduce 3 (.keep 2 .scalar)),
  ("empty_fiber", .keep 2 (.reduce 0 .scalar)),
  ("empty_output", .keep 0 (.reduce 3 .scalar)),
  ("unit_reduced", .reduce 1 (.keep 2 (.reduce 1 .scalar))),
  ("mixed_empty", .reduce 0 (.keep 2 (.reduce 3 .scalar)))
]

#eval show IO Unit from do
  for profile in (profiles : List (String × Plan)) do
    let name := profile.1
    let plan : Plan := profile.2
    let outputCount := LinearIndex.elementCount plan.outputShape
    IO.println s!"REDUCTION_COUNT name={name} outputs={outputCount} fiber={plan.fiberCount}"
    let input : Tensor plan.inputShape Int := fun index =>
      (LinearIndex.linearize plan.inputShape index).val + 1
    for position in List.finRange outputCount do
      let output := LinearIndex.delinearize plan.outputShape position
      let values := fiberValues plan input output
      let coordinates := (List.finRange plan.fiberCount).map fun fiber =>
        let reduced := LinearIndex.delinearize (shape plan)
          (Fin.cast (elementCount_shape plan).symm fiber)
        input (mergeIndex plan output reduced)
      let sum := reduceTensor plan (· + ·) 5 input output
      let negative := reduceTensor plan (· + ·) 0 (Tensor.map Neg.neg input) output
      let constant := reduceTensor plan (· + ·) 7 (Tensor.constant (3 : Int)) output
      let minimum := reduceTensor plan min 5 (Tensor.constant (3 : Int)) output
      let maximum := reduceTensor plan max 5 (Tensor.constant (7 : Int)) output
      let record := s!"REDUCTION name={name} output={position.val} fiber={values} " ++
        s!"coords={coordinates} sum={sum} neg={negative} constant={constant} " ++
        s!"min={minimum} max={maximum}"
      IO.println record
