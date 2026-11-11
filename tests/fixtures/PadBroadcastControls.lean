import TensorRewrite.Theory.PadBroadcastCounterexamples

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Deliberately nonassociative with zero as both identities. -/
def padBroadcastOperation (first second : Int) : Int :=
  if first = 0 then second else if second = 0 then first else first + 2 * second

/-- Observe original Pad/window evaluation and the actual derived target and conversion. -/
def runPadBroadcastControl (profile : Nat) (plan : PadBroadcast.Plan) : IO Unit := do
  let raw := PadBroadcast.padPlan plan
  let window := PadWindow.outerWindow raw
  let input : Tensor raw.inputShape Int :=
    fun index => Int.ofNat (LinearIndex.linearize raw.inputShape index).val + 1
  let padded := PadWindow.pad raw 0 input
  let source := ReductionWindow.reduce window padBroadcastOperation 0 0 padded
  let target := PadBroadcast.sequence plan input
  let converted := ReductionWindow.reduce window (· * ·) 1 1
    (Tensor.map (fun value => value + 1) padded)
  let convertedTarget := Tensor.map (fun value => value + 1) target
  let terminal := PadBroadcast.broadcastPlan plan
  IO.println s!"PAD_BROADCAST_COUNT profile={profile} rank={terminal.rank} inputs={LinearIndex.elementCount raw.inputShape} padded={LinearIndex.elementCount raw.paddedShape} outputs={LinearIndex.elementCount window.outputShape} kernels={LinearIndex.elementCount window.kernelShape} axes={(BroadcastWindow.broadcastAxes terminal).values.toList}"
  for position in List.finRange (LinearIndex.elementCount window.outputShape) do
    let output := LinearIndex.delinearize window.outputShape position
    let trace := ReductionWindow.values window 0 padded output
    let shiftedTrace := ReductionWindow.values window 1
      (Tensor.map (fun value => value + 1) padded) output
    IO.println s!"PAD_BROADCAST profile={profile} output={position.val} trace={trace} shifted_trace={shiftedTrace} source={source output} target={target output} converted={converted output} converted_target={convertedTarget output}"

/-- Retained dimensions have nonzero edge Pad canceled by actual signed outer cropping. -/
def padBroadcastKeep (extent low high : Nat) (tail : PadBroadcast.Plan) : PadBroadcast.Plan :=
  .keep {
    padding := ⟨extent, low, high, 1, by decide⟩
    window := {
      inputExtent := 0
      kernelExtent := 1
      stride := 1
      baseDilation := 1
      kernelDilation := 5
      paddingLow := -(low : Int)
      paddingHigh := -(high : Int)
      reversed := true
      stride_pos := by decide
      baseDilation_pos := by decide
      kernelDilation_pos := by decide }
    unitSpacing := rfl
    unitKernel := rfl
    unitStride := rfl
    unitBase := rfl
    cancelLow := rfl
    cancelHigh := rfl } tail

#eval show IO Unit from do
  let mut axisProfile := 0
  let mut profile := 0
  for padLow in List.range 3 do
    for padHigh in List.range 3 do
      for spacing in List.range 2 do
        for kernel in List.range 4 do
          for stride in List.range 2 do
            for base in List.range 2 do
              for low in List.range 5 do
                for high in List.range 5 do
                  for reversed in [false, true] do
                    let expansion : PadBroadcast.Expansion := {
                      padding := ⟨1, padLow, padHigh, spacing + 1, Nat.zero_lt_succ _⟩
                      window := {
                        inputExtent := 0
                        kernelExtent := kernel
                        stride := stride + 1
                        baseDilation := base + 1
                        kernelDilation := 1
                        paddingLow := Int.ofNat low - 2
                        paddingHigh := Int.ofNat high - 2
                        reversed := reversed
                        stride_pos := Nat.zero_lt_succ _
                        baseDilation_pos := Nat.zero_lt_succ _
                        kernelDilation_pos := by decide }
                      singleton := rfl
                      unitKernelDilation := rfl }
                    let outputs := (PadWindow.outerAxis expansion.padding expansion.window).outputExtent
                    IO.println s!"PAD_BROADCAST_AXIS profile={axisProfile} pad_low={padLow} pad_high={padHigh} spacing={spacing+1} kernel={kernel} stride={stride+1} base={base+1} low={Int.ofNat low-2} high={Int.ofNat high-2} reversed={reversed} outputs={outputs} eligible={decide expansion.Covers}"
                    axisProfile := axisProfile + 1
                    if covers : expansion.Covers then
                      runPadBroadcastControl profile (.expand expansion covers .scalar)
                      profile := profile + 1
  let full := PadBroadcast.coveredPlan
  let two : PadBroadcast.Expansion := {
    padding := ⟨1, 1, 1, 2, by decide⟩
    window := ⟨0, 2, 1, 1, 1, 0, 0, true, by decide, by decide, by decide⟩
    singleton := rfl
    unitKernelDilation := rfl }
  let extras := [PadBroadcast.Plan.scalar,
    padBroadcastKeep 0 2 1 .scalar, padBroadcastKeep 3 2 1 .scalar,
    padBroadcastKeep 3 1 2 full,
    .expand two (by decide) (padBroadcastKeep 3 2 1 .scalar),
    .expand two (by decide) (padBroadcastKeep 0 2 1 .scalar),
    .expand two (by decide) full,
    .expand two (by decide) (padBroadcastKeep 2 1 1 full),
    padBroadcastKeep 2 2 1 (padBroadcastKeep 3 1 2 full)]
  for extra in extras do
    runPadBroadcastControl profile extra
    profile := profile + 1
