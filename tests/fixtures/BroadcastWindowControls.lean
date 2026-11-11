import TensorRewrite.Theory.BroadcastWindowCounterexamples
import TensorRewrite.Theory.WindowTupleFloat

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory FloatLib.Floats

/-- A deliberately nonassociative reducer with two-sided identity zero. -/
def unitalOperation (first second : Int) : Int :=
  if first = 0 then second else if second = 0 then first else first + 2 * second

/-- Observe the actual window and constructed target, including the position of its live contribution. -/
def runBroadcastControl (profile : Nat) (plan : BroadcastWindow.Plan) : IO Unit := do
  let window := BroadcastWindow.windowPlan plan
  let input : Tensor window.inputShape Int :=
    fun index => Int.ofNat (LinearIndex.linearize window.inputShape index).val + 1
  let result := ReductionWindow.reduce window unitalOperation 0 0 input
  let target := BroadcastWindow.sequence plan input
  let boolResult := ReductionWindow.reduce window (fun a b => a != b) false false
    (Tensor.map (fun value => decide (value % 2 = 0)) input)
  let boolTarget := Tensor.map (fun value => decide (value % 2 = 0)) target
  IO.println s!"BROADCAST_COUNT profile={profile} rank={plan.rank} inputs={LinearIndex.elementCount window.inputShape} outputs={LinearIndex.elementCount window.outputShape} kernels={LinearIndex.elementCount window.kernelShape} compact_rank={(BroadcastWindow.compactPlan plan).outputRank} axes={(BroadcastWindow.broadcastAxes plan).values.toList}"
  for position in List.finRange (LinearIndex.elementCount window.outputShape) do
    let output := LinearIndex.delinearize window.outputShape position
    let trace := ReductionWindow.values window 0 input output
    let live := (BroadcastWindow.livePosition plan output).val
    IO.println s!"BROADCAST profile={profile} output={position.val} trace={trace} live={live} source={result output} target={target output} bool_source={boolResult output} bool_target={boolTarget output}"

/-- Generic tuple transport over arbitrary geometries and a nonidentity state representation. -/
def runTupleControl {rank : Nat} (name : String) (plan : ReductionWindow.Plan rank) : IO Unit := do
  let input : Tensor plan.inputShape Int :=
    fun index => Int.ofNat (LinearIndex.linearize plan.inputShape index).val + 1
  let operation (first second : Fin 1 → Int) : Fin 1 → Int :=
    fun _ => 10 * first 0 + second 0
  let source := WindowTupleFamily.source .singleton plan operation (fun _ => 7) (fun _ => -3)
    (fun _ => input)
  let target := WindowTupleFamily.target .singleton plan operation (fun _ => 7) (fun _ => -3)
    (fun _ => input)
  let shift : Int ≃ Int := {
    toFun := fun value => value + 1
    invFun := fun value => value - 1
    left_inv := by intro value; change (value + 1) - 1 = value; omega
    right_inv := by intro value; change (value - 1) + 1 = value; omega }
  let scalar := ReductionWindow.reduce plan (fun a b => 10*a+b) 7 (-3) input
  let shifted := ReductionWindow.reduce plan (WindowTransport.operation shift (fun a b => 10*a+b))
    8 (-2) (Tensor.map shift input)
  IO.println s!"TUPLE_COUNT name={name} outputs={LinearIndex.elementCount plan.outputShape}"
  for position in List.finRange (LinearIndex.elementCount plan.outputShape) do
    let output := LinearIndex.delinearize plan.outputShape position
    IO.println s!"TUPLE name={name} output={position.val} source={source 0 output} target={target 0 output} scalar={scalar output} shifted={shifted output}"

/- Arbitrary positive-stride singleton configurations include accepted and rejected coverage. -/
#eval show IO Unit from do
  for rule in WindowTupleFamily.allRules do
    match rule with | .singleton => IO.println "TUPLE_RULE singleton"
  let mut profile := 0
  let mut axisProfile := 0
  for kernel in List.range 5 do
    for stride in List.range 3 do
      for base in List.range 2 do
        for low in List.range 9 do
          for high in List.range 7 do
            for reversed in [false, true] do
              let expansion : BroadcastWindow.Expansion :=
                ⟨kernel, ⟨stride + 1, Nat.zero_lt_succ _⟩, ⟨base + 1, Nat.zero_lt_succ _⟩,
                  Int.ofNat low - 2, Int.ofNat high - 2, reversed⟩
              let eligible := decide expansion.Covers
              IO.println s!"BROADCAST_AXIS profile={axisProfile} kernel={kernel} stride={stride+1} base={base+1} low={Int.ofNat low-2} high={Int.ofNat high-2} reversed={reversed} outputs={expansion.axis.outputExtent} eligible={eligible}"
              axisProfile := axisProfile + 1
              if covers : expansion.Covers then
                runBroadcastControl profile (.expand expansion covers .scalar)
                profile := profile + 1
  let pair := BroadcastWindow.pairPlan
  let triple : BroadcastWindow.Plan :=
    .expand ⟨3, ⟨1, by decide⟩, ⟨2, by decide⟩, 2, 2, false⟩ (by decide) .scalar
  let keep (extent : Nat) (tail : BroadcastWindow.Plan) : BroadcastWindow.Plan :=
    .keep (FullSpanWindow.keptAxis extent) ⟨rfl, rfl, rfl, rfl, rfl⟩ tail
  let decorated : BroadcastWindow.Plan := .keep
    { FullSpanWindow.keptAxis 3 with
      kernelDilation := 5
      kernelDilation_pos := by decide
      reversed := true }
    ⟨rfl, rfl, rfl, rfl, rfl⟩ pair
  let extras := [BroadcastWindow.Plan.scalar, keep 0 .scalar, keep 3 .scalar,
    keep 3 pair, .expand BroadcastWindow.coveredPair (by decide) (keep 3 .scalar),
    .expand BroadcastWindow.coveredPair (by decide) (keep 0 .scalar),
    .expand BroadcastWindow.coveredPair (by decide) triple,
    .expand BroadcastWindow.coveredPair (by decide) (keep 2 triple), decorated]
  for extra in extras do
    runBroadcastControl profile extra
    profile := profile + 1
  runTupleControl "scalar" (show ReductionWindow.Plan 0 from ⟨Fin.elim0⟩)
  runTupleControl "covered" (BroadcastWindow.windowPlan pair)
  runTupleControl "empty_kernel" (show ReductionWindow.Plan 1 from
    ⟨fun _ => { BroadcastWindow.uncovered.axis with kernelExtent := 0 }⟩)
  runTupleControl "empty_output" (show ReductionWindow.Plan 1 from
    ⟨fun _ => { BroadcastWindow.uncovered.axis with paddingLow := -2, paddingHigh := 0 }⟩)

#eval runTupleControl "nontrivial" (show ReductionWindow.Plan 1 from ⟨fun _ => {
  inputExtent := 3
  kernelExtent := 2
  stride := 2
  baseDilation := 2
  kernelDilation := 2
  paddingLow := 2
  paddingHigh := 1
  reversed := true
  stride_pos := by decide
  baseDilation_pos := by decide
  kernelDilation_pos := by decide }⟩)

/-- Library binary32 addition keeps actual initializer/padding and the chosen contribution order. -/
def runTupleFloat (name : String) (initial padding : Nat) (words : List Nat) (padded : Bool) :
    IO Unit := do
  let plan : ReductionWindow.Plan 1 := ⟨fun _ => {
    inputExtent := words.length
    kernelExtent := words.length + (if padded then 2 else 0)
    stride := 1
    baseDilation := 1
    kernelDilation := 1
    paddingLow := if padded then 1 else 0
    paddingHigh := if padded then 1 else 0
    reversed := false
    stride_pos := by decide
    baseDilation_pos := by decide
    kernelDilation_pos := by decide }⟩
  let input : Tensor plan.inputShape Binary32 :=
    fun index => ExecFloat.Binary.ofNatBits (words.getD (index 0).val 0)
  let operation (first second : Fin 1 → Binary32) : Fin 1 → Binary32 :=
    fun _ => ExecFloat.add (first 0) (second 0)
  let source := WindowTupleFamily.source .singleton plan operation
    (fun _ => ExecFloat.Binary.ofNatBits initial) (fun _ => ExecFloat.Binary.ofNatBits padding)
    (fun _ => input)
  let target := WindowTupleFamily.target .singleton plan operation
    (fun _ => ExecFloat.Binary.ofNatBits initial) (fun _ => ExecFloat.Binary.ofNatBits padding)
    (fun _ => input)
  for position in List.finRange (LinearIndex.elementCount plan.outputShape) do
    let output := LinearIndex.delinearize plan.outputShape position
    IO.println s!"TUPLE_F32 name={name} source={ExecFloat.Binary.toNatBits (source 0 output)} target={ExecFloat.Binary.toNatBits (target 0 output)}"

#eval show IO Unit from do
  runTupleFloat "finite_order" 0 0 [0x4b800000, 0x3f800000, 0xcb800000] false
  runTupleFloat "finite_reverse" 0 0 [0xcb800000, 0x3f800000, 0x4b800000] false
  runTupleFloat "negative_zero" 0 0 [0x80000000] false
  runTupleFloat "negative_initial" 0x80000000 0 [0x80000000] false
  runTupleFloat "empty_negative_initial" 0x80000000 0 [] false
  runTupleFloat "subnormals" 0 0 [1, 2] false
  runTupleFloat "half_ulp" 0 0 [0x3f800000, 0x33800000] false
  runTupleFloat "padded_negative_zero" 0x80000000 0 [0x80000000] true
