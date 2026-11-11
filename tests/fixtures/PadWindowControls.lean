import TensorRewrite.Theory.PadWindowCounterexamples

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Small window attributes; positive parameters are encoded by their predecessors. -/
def padControlWindow (kernel stride base dilation : Nat) (low high : Int) (rev : Bool) :
    Convolution.Axis where
  inputExtent := 999
  kernelExtent := kernel
  stride := stride + 1
  baseDilation := base + 1
  kernelDilation := dilation + 1
  paddingLow := low
  paddingHigh := high
  reversed := rev
  stride_pos := Nat.zero_lt_succ _
  baseDilation_pos := Nat.zero_lt_succ _
  kernelDilation_pos := Nat.zero_lt_succ _

/-- Include cropping, both dilations, reversal, striding and empty windows. -/
def padControlWindows : List Convolution.Axis := [
  padControlWindow 1 0 0 0 0 0 false,
  padControlWindow 3 0 0 0 1 1 false,
  padControlWindow 2 1 0 1 (-1) 2 false,
  padControlWindow 2 0 1 0 2 1 false,
  padControlWindow 3 1 2 1 (-2) 1 true,
  padControlWindow 0 1 1 0 (-1) 0 false]

/-- Compare actual Pad/window graphs, complete lists and heterogeneous converted folds. -/
def runPadWindowControl {rank : Nat} (profile : Nat) (plan : PadWindow.Plan rank) : IO Unit := do
  let outer := PadWindow.outerWindow plan
  let fused := PadWindow.fusedWindow plan
  let input : Tensor plan.inputShape Int := fun index =>
    Int.ofNat (LinearIndex.linearize plan.inputShape index).val + 1
  let padded := PadWindow.pad plan (-3) input
  let source := ReductionWindow.reduce outer (fun a b => 10*a+b) 7 (-3) padded
  let target := ReductionWindow.reduce fused (fun a b => 10*a+b) 7 (-3) input
  let convert (value : Int) : Bool := value < 0
  let boolSource := ReductionWindow.reduce outer (fun a b => !(a && b)) true true
    (Tensor.map convert padded)
  let boolTarget := ReductionWindow.reduce fused (fun a b => !(a && b)) true true
    (Tensor.map convert input)
  IO.println s!"PAD_COUNT profile={profile} rank={rank} inputs={LinearIndex.elementCount plan.inputShape} padded={LinearIndex.elementCount plan.paddedShape} outputs={LinearIndex.elementCount outer.outputShape} fused={LinearIndex.elementCount fused.outputShape} kernels={LinearIndex.elementCount outer.kernelShape}"
  for position in List.finRange (LinearIndex.elementCount outer.outputShape) do
    let output := LinearIndex.delinearize outer.outputShape position
    let targetOutput := PadWindow.outputIndex plan output
    let trace := ReductionWindow.values outer (-3) padded output
    let fusedTrace := ReductionWindow.values fused (-3) input targetOutput
    IO.println s!"PAD profile={profile} output={position.val} trace={trace} fused_trace={fusedTrace} source={source output} target={target targetOutput} bool_source={boolSource output} bool_target={boolTarget targetOutput}"

#eval show IO Unit from do
  let mut profile := 0
  for n in List.range 4 do
    for low in List.range 3 do
      for high in List.range 3 do
        for spacing in List.range 3 do
          for window in padControlWindows do
            let plan : PadWindow.Plan 1 := {
              padding := fun _ => ⟨n, low, high, spacing + 1, Nat.zero_lt_succ _⟩
              window := fun _ => window }
            runPadWindowControl profile plan
            profile := profile + 1
  runPadWindowControl profile (show PadWindow.Plan 0 from ⟨Fin.elim0, Fin.elim0⟩)
  profile := profile + 1
  for first in List.range 6 do
    let padding : Fin 2 → PadWindow.PaddingAxis :=
      Fin.cases ⟨2, 1, 2, 2, by decide⟩ (fun _ => ⟨first % 3, 0, 1, 3, by decide⟩)
    let window := Fin.cases (padControlWindows.getD first (padControlWindow 1 0 0 0 0 0 false))
      (fun _ => (padControlWindows.getD ((first + 3) % 6) (padControlWindow 1 0 0 0 0 0 false)))
    runPadWindowControl profile ⟨padding, window⟩
    profile := profile + 1
