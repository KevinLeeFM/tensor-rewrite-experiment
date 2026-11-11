import TensorRewrite.Theory.PrefixWindowCounterexamples

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Nonzero stride outputs before the scan axis. -/
def strideBefore : PrefixWindow.Plan 2 :=
  .keep 3 ⟨2, by decide⟩ (PrefixWindow.shortScan 2)

/-- Nonzero stride outputs after the scan axis. -/
def strideAfter : PrefixWindow.Plan 2 :=
  .scan 2 (fun _ => 3) (fun _ => ⟨2, by decide⟩)

/-- Nonzero stride outputs on both sides of a scan axis. -/
def strideBoth : PrefixWindow.Plan 3 :=
  .keep 3 ⟨2, by decide⟩ (.scan 3 (fun _ => 3) (fun _ => ⟨2, by decide⟩))

/-- Observe actual source values and the independently defined prefix at a chosen output. -/
def runStrideControl {rank : Nat} (name : String) (plan : PrefixWindow.Plan rank)
    (output : Index (PrefixWindow.windowPlan plan).outputShape) : IO Unit := do
  let window := PrefixWindow.windowPlan plan
  let input : Tensor window.inputShape Nat :=
    fun index => (LinearIndex.linearize window.inputShape index).val + 1
  let trace := ReductionWindow.values window 0 input output
  let direct := PrefixWindow.prefixValues plan input output
  let value := ReductionWindow.reduce window (fun a b => 10*a+b) 0 0 input output
  IO.println s!"PREFIX_STRIDE name={name} trace={trace} direct={direct} value={value}"

#eval show IO Unit from do
  runStrideControl "before" strideBefore (fun _ => ⟨1, by decide +revert⟩)
  runStrideControl "after" strideAfter (fun _ => ⟨1, by decide +revert⟩)
  runStrideControl "both_last" strideBoth
    (fun axis => ⟨if axis.val = 1 then 2 else 1, by decide +revert⟩)
  runStrideControl "both_interior" strideBoth (fun _ => ⟨1, by decide +revert⟩)
