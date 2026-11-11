import TensorRewrite.Theory.FullSpanWindowProof

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Exhaustive small axis plans: zero extents and every keep/reduce combination. -/
def fullSpanPlans : Nat → List Reduction.Plan
  | 0 => [.scalar]
  | depth + 1 => (List.range 4).flatMap fun extent =>
      (fullSpanPlans depth).flatMap fun tail => [.keep extent tail, .reduce extent tail]

#eval show IO Unit from do
  let mut profile := 0
  for depth in List.range 4 do
    for plan in fullSpanPlans depth do
      let window := FullSpanWindow.windowPlan plan
      let input : Tensor window.inputShape Nat :=
        fun index => (LinearIndex.linearize window.inputShape index).val + 1
      let reduced := Reduction.reduceTensor plan (fun a b => 10*a+b) 7
        (fun index => input (FullSpanWindow.inputIndex plan index))
      let reshaped := Reshape.reshapeTensor reduced window.outputShape
        (FullSpanWindow.output_count plan).symm
      let result := ReductionWindow.reduce window (fun a b => 10*a+b) 7 999 input
      IO.println s!"FULLSPAN_COUNT profile={profile} rank={depth} inputs={LinearIndex.elementCount window.inputShape} outputs={LinearIndex.elementCount window.outputShape} kernels={LinearIndex.elementCount window.kernelShape}"
      for position in List.finRange (LinearIndex.elementCount window.outputShape) do
        let output := LinearIndex.delinearize window.outputShape position
        let trace := ReductionWindow.values window 999 input output
        let fiber := Reduction.fiberValues plan
          (fun index => input (FullSpanWindow.inputIndex plan index))
          (FullSpanWindow.outputIndex plan output)
        IO.println s!"FULLSPAN profile={profile} output={position.val} trace={trace} fiber={fiber} window={result output} reshape={reshaped output}"
      profile := profile + 1
