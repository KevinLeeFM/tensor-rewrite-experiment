import TensorRewrite.Theory.ScatterIndicesCounterexample
import Mathlib.Tactic.FinCases

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Encode an absent explicit vector axis separately from every actual raw dimension. -/
def vectorAxisCode {components batchRank : Nat} {shape : Shape batchRank}
    (layout : IndexVector.Layout components shape) : Int :=
  match layout.vectorAxis? with | none => -1 | some axis => axis

/-- Exercise original raw values, both tensor round trips, vector-axis movement and scalar decoding. -/
def readerControl {components batchRank : Nat} {shape : Shape batchRank} (profile : Nat)
    (source target : IndexVector.Layout components shape) : IO Unit := do
  let raw : Tensor source.rawShape Int := fun index =>
    Int.ofNat (((LinearIndex.linearize source.rawShape index).val * 3 + 7) % 17) - 8
  let packed := IndexVector.pack source (IndexVector.read source raw)
  let moved := IndexVector.relayout source target raw
  let signed := IndexVector.read source
    (Tensor.map (fun x : Int => (BitVec.ofInt 4 x).toInt) raw)
  let unsigned := IndexVector.read source
    (Tensor.map (fun x : Int => (BitVec.ofInt 4 x).toNat) raw)
  IO.println s!"READER_COUNT profile={profile} components={components} batch={(Vector.ofFn shape).toList} raw={(Vector.ofFn source.rawShape).toList} axis={vectorAxisCode source} target_raw={(Vector.ofFn target.rawShape).toList} target_axis={vectorAxisCode target}"
  for position in List.finRange (LinearIndex.elementCount source.rawShape) do
    let coordinate := LinearIndex.delinearize source.rawShape position
    IO.println s!"READER_RAW profile={profile} position={position.val} value={raw coordinate} packed={packed coordinate}"
  for position in List.finRange (LinearIndex.elementCount shape) do
    let batch := LinearIndex.delinearize shape position
    for component in List.finRange components do
      let coordinate := source.rawIndex batch component
      IO.println s!"READER_VALUE profile={profile} batch={position.val} component={component.val} coordinate={(Vector.ofFn (fun axis => (coordinate axis).val)).toList} position={(LinearIndex.linearize source.rawShape coordinate).val} value={IndexVector.read source raw batch component} moved={IndexVector.read target moved batch component} signed={signed batch component} unsigned={unsigned batch component}"
  for position in List.finRange (LinearIndex.elementCount target.rawShape) do
    let coordinate := LinearIndex.delinearize target.rawShape position
    IO.println s!"READER_TARGET profile={profile} position={position.val} value={moved coordinate}"

/-- Actual Scatter with both raw tensors, a derived canonical evaluator and vector-axis relayout. -/
def indexScatterControl {components : Nat} (profile : Nat) (plan : ScatterLayout.Plan components)
    (layout : IndexVector.Layout components plan.updateAxes.outputShape) : IO Unit := do
  let indices : Tensor layout.rawShape Int := fun raw =>
    Int.ofNat ((LinearIndex.linearize layout.rawShape raw).val % 4) - 1
  let updates : Tensor plan.updateAxes.inputShape Int := fun raw =>
    Int.ofNat ((LinearIndex.linearize plan.updateAxes.inputShape raw).val + 1)
  let base : Tensor plan.operandShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize plan.operandShape index).val + 2)
  let separate : Tensor plan.operandShape Int := fun index =>
    3 * Int.ofNat (LinearIndex.linearize plan.operandShape index).val + 1
  let events := ScatterIndices.entries plan layout indices updates
  let decimal := ScatterIndices.scatter plan layout (fun a b => 10 * a + b) base indices updates
  let canonical := OrderedScatter.scatter plan.toOrdered (fun a b => 10 * a + b) base
    (IndexVector.read layout indices) (ScatterLayout.adaptUpdates plan updates)
  let front := IndexVector.Layout.here components plan.updateAxes.outputShape
  let moved := ScatterIndices.scatter plan front (fun a b => 10 * a + b) base
    (IndexVector.relayout layout front indices) updates
  let unsigned := ScatterIndices.scatter plan layout (fun a b => 10 * a + b) base
    (Tensor.map (fun x : Int => Int.ofNat (BitVec.ofInt 4 x).toNat) indices) updates
  let wordBase := Tensor.map (fun x : Int => BitVec.ofInt 4 x) base
  let wordSeparate := Tensor.map (fun x : Int => BitVec.ofInt 4 x) separate
  let wordUpdates := Tensor.map (fun x : Int => BitVec.ofInt 4 x) updates
  let wordSource := Tensor.map₂ (· + ·) wordSeparate
    (ScatterIndices.scatter plan layout (· + ·) wordBase indices wordUpdates)
  let wordTarget := ScatterIndices.scatter plan layout (· + ·)
    (Tensor.map₂ (· + ·) wordSeparate wordBase) indices wordUpdates
  IO.println s!"INDEX_COUNT profile={profile} components={components} index_raw={(Vector.ofFn layout.rawShape).toList} index_axis={vectorAxisCode layout} operand={(Vector.ofFn plan.operandShape).toList} update_raw={(Vector.ofFn plan.updateAxes.inputShape).toList} batch={(Vector.ofFn plan.updateAxes.outputShape).toList} compact={(Vector.ofFn (ReductionFiber.shape plan.updateAxes)).toList} full={(Vector.ofFn plan.windows.fullShape).toList} axes={plan.indexAxes.values.toList} events={events.length}"
  for (entry, ordinal) in events.zipIdx do
    let target := match entry.target with
      | none => (-1 : Int)
      | some index => (LinearIndex.linearize plan.operandShape index).val
    IO.println s!"INDEX_EVENT profile={profile} event={ordinal} target={target} value={entry.value}"
  for position in List.finRange (LinearIndex.elementCount plan.operandShape) do
    let index := LinearIndex.delinearize plan.operandShape position
    IO.println s!"INDEX_VALUE profile={profile} output={position.val} decimal={decimal index} canonical={canonical index} moved={moved index} unsigned={unsigned index} word_source={(wordSource index).toNat} word_target={(wordTarget index).toNat}"

/-- Reader controls cover all vector-axis positions through raw rank three and implicit axes. -/
def readerControls : IO Unit := do
  let scalar : Shape 0 := Fin.elim0
  let mut profile := 0
  for components in List.range 4 do
    readerControl profile (.here components scalar) (.here components scalar)
    profile := profile + 1
    for batch in List.range 3 do
      let shape := Fin.cases batch scalar
      readerControl profile (.here components shape) (.batch batch (.here components scalar))
      profile := profile + 1
      readerControl profile (.batch batch (.here components scalar)) (.here components shape)
      profile := profile + 1
    for b0 in List.range 3 do
      for b1 in List.range 3 do
        let shape := Fin.cases b0 (Fin.cases b1 scalar)
        readerControl profile (.here components shape) (.here components shape)
        profile := profile + 1
        readerControl profile (.batch b0 (.here components (Fin.cases b1 scalar)))
          (.here components shape)
        profile := profile + 1
        readerControl profile (.batch b0 (.batch b1 (.here components scalar)))
          (.here components shape)
        profile := profile + 1
  readerControl profile (.implicit scalar) (.here 1 scalar)
  profile := profile + 1
  readerControl profile (.here 1 scalar) (.implicit scalar)
  profile := profile + 1
  for batch in List.range 3 do
    let shape := Fin.cases batch scalar
    readerControl profile (.implicit shape) (.here 1 shape)
    profile := profile + 1
    readerControl profile (.here 1 shape) (.implicit shape)
    profile := profile + 1
  for b0 in List.range 3 do
    for b1 in List.range 3 do
      let shape := Fin.cases b0 (Fin.cases b1 scalar)
      readerControl profile (.batch b0 (.implicit (Fin.cases b1 scalar))) (.here 1 shape)
      profile := profile + 1
      readerControl profile (.here 1 shape) (.implicit shape)
      profile := profile + 1

/-- Rank-one update geometry with a chosen actual vector component count. -/
def rawOnePlan (extent window batch : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .keep batch (.reduce window .scalar)
  windows := .keep window .scalar
  operandShape := fun _ => extent
  indexAxes := ⟨#v[0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun a b _ => Subsingleton.elim a b

/-- Inserted front window axis with a reversed actual two-component operand-axis map. -/
def rawTwoPlan (extent window batch : Nat) : ScatterLayout.Plan 2 where
  updateAxes := .reduce window (.keep batch .scalar)
  windows := .insert (.keep window .scalar)
  operandShape := Fin.cases 2 (fun _ => extent)
  indexAxes := ⟨#v[1, 0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := by
    intro a b same
    fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]

/-- A zero-length explicit vector leaves nonempty batches/windows available. -/
def rawZeroPlan (extent window batch : Nat) : ScatterLayout.Plan 0 where
  updateAxes := .keep batch (.reduce window .scalar)
  windows := .keep window .scalar
  operandShape := fun _ => extent
  indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  injective := fun axis => Fin.elim0 axis

/-- A shared rank-two batch with interleaved raw update windows and a middle inserted window axis. -/
def rawMultiplePlan (b0 b1 window : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .keep b0 (.reduce window (.keep b1 (.reduce window .scalar)))
  windows := .keep window (.insert (.keep window .scalar))
  operandShape := fun _ => 2
  indexAxes := ⟨#v[2], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun a b _ => Subsingleton.elim a b

#eval readerControls

#eval show IO Unit from do
  let scalar : Shape 0 := Fin.elim0
  let mut profile := 0
  for extent in List.range 3 do
    for window in List.range 3 do
      for batch in List.range 3 do
        let one := rawOnePlan extent window batch
        let back : IndexVector.Layout 1 one.updateAxes.outputShape := by
          change IndexVector.Layout 1 (Fin.cases batch scalar)
          exact .batch batch (.here 1 scalar)
        indexScatterControl profile one (.here 1 one.updateAxes.outputShape)
        profile := profile + 1
        indexScatterControl profile one back
        profile := profile + 1
        indexScatterControl profile one (.implicit one.updateAxes.outputShape)
        profile := profile + 1
        let two := rawTwoPlan extent window batch
        let back : IndexVector.Layout 2 two.updateAxes.outputShape := by
          change IndexVector.Layout 2 (Fin.cases batch scalar)
          exact .batch batch (.here 2 scalar)
        indexScatterControl profile two (.here 2 two.updateAxes.outputShape)
        profile := profile + 1
        indexScatterControl profile two back
        profile := profile + 1
        let zero := rawZeroPlan extent window batch
        let back : IndexVector.Layout 0 zero.updateAxes.outputShape := by
          change IndexVector.Layout 0 (Fin.cases batch scalar)
          exact .batch batch (.here 0 scalar)
        indexScatterControl profile zero (.here 0 zero.updateAxes.outputShape)
        profile := profile + 1
        indexScatterControl profile zero back
        profile := profile + 1
  for b0 in List.range 3 do
    for b1 in List.range 3 do
      for window in List.range 3 do
        let plan := rawMultiplePlan b0 b1 window
        let middle : IndexVector.Layout 1 plan.updateAxes.outputShape := by
          change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
          exact .batch b0 (.here 1 (Fin.cases b1 scalar))
        let back : IndexVector.Layout 1 plan.updateAxes.outputShape := by
          change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
          exact .batch b0 (.batch b1 (.here 1 scalar))
        indexScatterControl profile plan (.here 1 plan.updateAxes.outputShape)
        profile := profile + 1
        indexScatterControl profile plan middle
        profile := profile + 1
        indexScatterControl profile plan back
        profile := profile + 1
        indexScatterControl profile plan (.implicit plan.updateAxes.outputShape)
        profile := profile + 1
  for batch in List.range 4 do
    let plan : ScatterLayout.Plan 0 := {
      updateAxes := .keep batch .scalar
      windows := .scalar
      operandShape := Fin.elim0
      indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
      injective := fun axis => Fin.elim0 axis
    }
    indexScatterControl profile plan (.here 0 plan.updateAxes.outputShape)
    profile := profile + 1
    indexScatterControl profile plan (.batch batch (.here 0 scalar))
    profile := profile + 1
