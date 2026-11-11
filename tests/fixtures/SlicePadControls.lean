import TensorRewrite.Theory.SlicePadCounterexamples

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Theory

private def checkAxis (n outputs step : Nat) (low : Int) : IO Unit := do
  let axis : SlicePad.Axis := ⟨n, outputs, step+1, low, by omega⟩
  let legal := decide (SliceShape.IsWellFormed axis.inputExtent axis.count axis.attributes)
  let total := axis.first + axis.count + (axis.outputExtent - axis.last)
  let row := s!"FACTOR_AXIS n={n} outputs={outputs} stride={step+1} low={low} " ++
    s!"first={axis.first} last={axis.last} count={axis.count} start={axis.start} " ++
    s!"limit={axis.limit} shape={total} legal={legal}"
  IO.println row

private def axis (n k : Nat) (s b d : Nat := 0) (lo hi : Int := 0)
    (rev : Bool := false) : Convolution.Axis := {
  inputExtent := n
  kernelExtent := k
  stride := s+1
  baseDilation := b+1
  kernelDilation := d+1
  paddingLow := lo
  paddingHigh := hi
  reversed := rev
  stride_pos := by omega
  baseDilation_pos := by omega
  kernelDilation_pos := by omega
}

private def plan (axes : List Convolution.Axis) : ReductionWindow.Plan axes.length :=
  ⟨fun i => axes[i]⟩

private def checkPlan {rank : Nat} (name : String) (p : ReductionWindow.Plan rank) : IO Unit := do
  let outputs := LinearIndex.elementCount p.outputShape
  let eligible := (List.finRange rank).all fun i =>
    (p.window i).kernelExtent == 1 && (p.window i).baseDilation == 1
  IO.println s!"FACTOR_COUNT name={name} outputs={outputs} eligible={eligible}"
  let input : Tensor p.inputShape Int := fun i => (LinearIndex.linearize p.inputShape i).val+1
  for position in List.finRange outputs do
    let output := LinearIndex.delinearize p.outputShape position
    let actual := SlicePad.graph p (-9) (fun x => 2*x+7) input output
    let gather := ReductionWindow.gatherMap p (-9) (fun x => 2*x+7) input output
    let boolean := SlicePad.graph p false (fun x => x%2 == 0) input output
    let minimum := SlicePad.graph p 5 (fun x => min x 5) input output
    let maximum := SlicePad.graph p 5 (fun x => max x 5) input output
    let zeroGraph := SlicePad.graph p 0 id input output
    let zeroWindow := ReductionWindow.reduce p (· + ·) 0 0 input output
    let row := s!"FACTOR name={name} output={position.val} graph={actual} gather={gather} " ++
      s!"boolean={boolean} min={minimum} max={maximum} zero_graph={zeroGraph} " ++
      s!"zero_window={zeroWindow}"
    IO.println row

#eval do
  for n in List.range 5 do
    for outputs in List.range 5 do
      for step in List.range 3 do
        for low in List.range 9 do
          checkAxis n outputs step (Int.ofNat low - 4)
  checkPlan "scalar" (plan [])
  checkPlan "pointwise" (plan [axis 3 1 0 0 6 0 0 true])
  checkPlan "unit_padding" (plan [axis 2 1 0 0 0 1 2])
  checkPlan "unit_crop" (plan [axis 4 1 0 0 0 (-1) (-1)])
  checkPlan "unit_stride" (plan [axis 5 1 1 0 0 1])
  checkPlan "base_holes" (plan [axis 3 1 0 1 0])
  checkPlan "kernel_dilation" (plan [axis 6 3 0 0 1 1 1])
  checkPlan "kernel_reversal" (plan [axis 3 3 0 0 0 0 0 true])
  checkPlan "empty_input" (plan [axis 0 2 0 0 0 2 2])
  checkPlan "empty_kernel" (plan [axis 2 0 0 0 0])
  checkPlan "empty_output" (plan [axis 2 5 0 0 0])
  checkPlan "mixed_unit" (plan [axis 2 1 0 0 0 1,axis 3 1 0 0 0 (-1)])
  checkPlan "crop_all_low" (plan [axis 2 1 0 0 0 (-2) 3])
  checkPlan "crop_all_high" (plan [axis 2 1 0 0 0 3 (-2)])
  checkPlan "mixed_kernel" (plan [axis 2 2 0 0 0,axis 3 2 0 0 0 1])
