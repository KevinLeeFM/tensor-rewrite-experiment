import TensorRewrite.Theory.PrefixWindowCounterexamples

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- All small retained shapes and independent positive strides. -/
def prefixRetainedConfigurations : (rank : Nat) → List (Shape rank × (Fin rank → ℕ+))
  | 0 => [(Fin.elim0, Fin.elim0)]
  | rank + 1 => (List.range 3).flatMap fun extent =>
      (List.range 2).flatMap fun stride => (prefixRetainedConfigurations rank).map fun tail =>
        (Fin.cases extent tail.1, Fin.cases ⟨stride + 1, Nat.zero_lt_succ _⟩ tail.2)

/-- Cover every scan position with empty/nonempty extents, arbitrary retained strides and ranks1..3. -/
def prefixPlans : (rank : Nat) → List (PrefixWindow.Plan rank)
  | 0 => []
  | rank + 1 =>
    ((List.range 6).flatMap fun extent => (prefixRetainedConfigurations rank).map fun tail =>
      .scan extent tail.1 tail.2) ++
    ((List.range 3).flatMap fun extent => (List.range 2).flatMap fun stride =>
      (prefixPlans rank).map fun tail => .keep extent ⟨stride + 1, Nat.zero_lt_succ _⟩ tail)

/-- Compare actual ordered windows, direct prefix filtering, exact counts and modular products. -/
def runPrefixControl {rank : Nat} (profile : Nat) (plan : PrefixWindow.Plan rank) : IO Unit := do
  let window := PrefixWindow.windowPlan plan
  let input : Tensor window.inputShape Int := fun index =>
    Int.ofNat (LinearIndex.linearize window.inputShape index).val + 1
  let source := ReductionWindow.reduce window (fun a b => 10*a+b) 7 2 input
  let neutral := ReductionWindow.reduce window (fun a b => 10*a+b) 0 0 input
  let count := ReductionWindow.reduce window (· + ·) 0 0 (Tensor.constant (1 : Nat))
  let product2 := ReductionWindow.reduce window (· + ·) 0 0 (Tensor.constant (3#2))
  let product32 := ReductionWindow.reduce window (· + ·) 0 0 (Tensor.constant (3#32))
  let product64 := ReductionWindow.reduce window (· + ·) 0 0 (Tensor.constant (3#64))
  let count2 := ReductionWindow.reduce window (· + ·) 0 0 (Tensor.constant (1#2))
  IO.println s!"PREFIX_COUNT profile={profile} rank={rank} scan={PrefixWindow.scanExtent plan} inputs={LinearIndex.elementCount window.inputShape} outputs={LinearIndex.elementCount window.outputShape} kernels={LinearIndex.elementCount window.kernelShape}"
  for position in List.finRange (LinearIndex.elementCount window.outputShape) do
    let output := LinearIndex.delinearize window.outputShape position
    let trace := ReductionWindow.values window 2 input output
    let direct :=  PrefixWindow.prefixValues plan input output
    let padding := PrefixWindow.paddingCount plan output
    let index := (PrefixWindow.coordinate plan (PrefixWindow.outputIndex plan output)).val
    let factor := ((List.replicate padding 2) ++ direct).foldl (fun a b => 10*a+b) 7
    let prefixFold := direct.foldl (fun a b => 10*a+b) 0
    IO.println s!"PREFIX profile={profile} output={position.val} index={index} padding={padding} trace={trace} prefix={direct} source={source output} factor={factor} neutral={neutral output} prefix_fold={prefixFold} count={count output} product2={(product2 output).toNat} product32={(product32 output).toNat} product64={(product64 output).toNat} count2u={(count2 output).toNat} count2s={(count2 output).toInt}"

#eval show IO Unit from do
  let mut profile := 0
  for rank in List.range 3 do
    for plan in prefixPlans (rank + 1) do
      runPrefixControl profile plan
      profile := profile + 1
  for width in [0, 1, 2, 3, 8, 32, 64] do
    let modulus := 2 ^ width
    let half := 2 ^ (width - 1)
    let counts := [0, 1, half - 1, half, half + 1, modulus - 1, modulus, modulus + 1]
    for count in counts.eraseDups do
      let encoded := BitVec.ofNat width count
      IO.println s!"PREFIX_CAST width={width} count={count} unsigned={encoded.toNat} signed={encoded.toInt}"
