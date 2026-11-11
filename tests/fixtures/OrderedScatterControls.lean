import TensorRewrite.Theory.OrderedScatterCounterexamples

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory FloatLib.Floats

/-- Several signed start patterns include overlap, repeats, partial and wholly dropped windows. -/
def scatterStart (mode batch component : Nat) : Int :=
  (match mode with
   | 0 => -2 | 1 => -1 | 2 => 0 | 3 => 1 | 4 => 3
   | 5 => (batch : Int) - 1 | 6 => 1 - (batch : Int)
   | _ => 2 * (batch % 2 : Nat) - 1) + component

/-- Evaluate actual events, values, tuple state, valid fusion and all four Add parameter-role pairs. -/
def runScatterControl {rank batchRank indexSize : Nat} (profile mode : Nat)
    (plan : OrderedScatter.Plan rank batchRank indexSize) (isMap : Bool := false) : IO Unit := do
  let indices : Tensor plan.batchShape (Fin indexSize → Int) := fun batch component =>
    scatterStart mode (LinearIndex.linearize plan.batchShape batch).val component.val
  let rightIndices : Tensor plan.batchShape (Fin indexSize → Int) :=
    fun batch component => indices batch component + 1
  let updates : Tensor plan.batchShape (Tensor plan.windowShape Int) := fun batch window =>
    Int.ofNat ((LinearIndex.linearize plan.batchShape batch).val *
      LinearIndex.elementCount plan.windowShape +
      (LinearIndex.linearize plan.windowShape window).val + 1)
  let rightUpdates := fun batch => Tensor.map (fun value => 2*value+1) (updates batch)
  let base : Tensor plan.operandShape Int :=
    fun index => (LinearIndex.linearize plan.operandShape index).val + 2
  let separate : Tensor plan.operandShape Int :=
    fun index => 3 * (LinearIndex.linearize plan.operandShape index).val + 1
  let events := OrderedScatter.entries plan indices updates
  let rightEvents := OrderedScatter.entries plan rightIndices rightUpdates
  let decimal := OrderedScatter.scatter plan (fun a b => 10*a+b) base indices updates
  let reverse := OrderedScatter.run (fun a b => 10*a+b) base events.reverse
  let translated := OrderedScatter.scatter plan (· + ·) (Tensor.map₂ (· + ·) separate base)
    indices updates
  let translationSource := Tensor.map₂ (· + ·) separate
    (OrderedScatter.scatter plan (· + ·) base indices updates)
  let pair := Tensor.map₂ (· + ·) (OrderedScatter.scatter plan (· + ·) base indices updates)
    (OrderedScatter.scatter plan (· + ·) separate rightIndices rightUpdates)
  let concatenated := OrderedScatter.run (· + ·) (Tensor.map₂ (· + ·) base separate)
    (events ++ rightEvents)
  let nested := OrderedScatter.run (· + ·)
    (OrderedScatter.run (· + ·) (Tensor.map₂ (· + ·) base separate) events) rightEvents
  let coupledBase : Tensor plan.operandShape (Fin 2 → Int) :=
    fun index component => if component.val = 0 then base index else -(base index)
  let coupledUpdates := fun batch window (component : Fin 2) =>
    if component.val = 0 then updates batch window else 1 - updates batch window
  let coupledOperation (first second : Fin 2 → Int) (component : Fin 2) : Int :=
    if component.val = 0 then first 0 + second 1 else first 0 + first 1 - second 0
  let coupled := OrderedScatter.scatter plan coupledOperation coupledBase indices coupledUpdates
  IO.println s!"SCATTER_COUNT profile={profile} mode={mode} operand={(Vector.ofFn plan.operandShape).toList} batch={(Vector.ofFn plan.batchShape).toList} window={(Vector.ofFn plan.windowShape).toList} axes={plan.indexAxes.values.toList} events={events.length} outputs={LinearIndex.elementCount plan.operandShape} map_case={isMap}"
  for (entry, ordinal) in events.zipIdx do
    let target := match entry.target with
      | none => (-1 : Int)
      | some index => (LinearIndex.linearize plan.operandShape index).val
    IO.println s!"SCATTER_EVENT profile={profile} event={ordinal} target={target} value={entry.value}"
  for position in List.finRange (LinearIndex.elementCount plan.operandShape) do
    let index := LinearIndex.delinearize plan.operandShape position
    let filtered := OrderedScatter.valuesAt events index
    let mapExpected := if isMap then 10*base index + (position.val+1 : Nat) else -1
    IO.println s!"SCATTER_VALUE profile={profile} output={position.val} trace={filtered} decimal={decimal index} reverse={reverse index} translation_source={translationSource index} translation_target={translated index} pair_source={pair index} concatenated={concatenated index} nested={nested index} coupled={[coupled index 0,coupled index 1]} map_expected={mapExpected}"
    for first in [ReducerIndex.ScatterRoles.Parameter.current, .update] do
      for second in [ReducerIndex.ScatterRoles.Parameter.current, .update] do
        let reducer := ReducerIndex.ScatterRoles.combine (width := 4) first second
        let wordBase := Tensor.map (BitVec.ofInt 4) base
        let wordSeparate := Tensor.map (BitVec.ofInt 4) separate
        let wordUpdates := fun batch => Tensor.map (BitVec.ofInt 4) (updates batch)
        let wordSource := Tensor.map₂ (· + ·) wordSeparate
          (OrderedScatter.scatter plan reducer wordBase indices wordUpdates)
        let wordTarget := OrderedScatter.scatter plan reducer
          (Tensor.map₂ (· + ·) wordSeparate wordBase) indices wordUpdates
        IO.println s!"SCATTER_ROLE profile={profile} output={position.val} first={repr first} second={repr second} source={(wordSource index).toNat} target={(wordTarget index).toNat}"

/-- One-dimensional full windows with a mapped signed index vector. -/
def scatterOnePlan (extent window batches : Nat) : OrderedScatter.Plan 1 1 1 where
  operandShape := fun _ => extent
  batchShape := fun _ => batches
  windowShape := fun _ => window
  indexAxes := ⟨#v[0], by decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- Rank-two index vectors may be unsorted or omit an operand axis. -/
def scatterTwoPlan (n0 n1 w0 w1 batches : Nat) : OrderedScatter.Plan 2 1 2 where
  operandShape := Fin.cases n0 (fun _ => n1)
  batchShape := fun _ => batches
  windowShape := Fin.cases w0 (fun _ => w1)
  indexAxes := ⟨#v[1,0], by decide⟩
  injective := by decide

/-- Rank-two scalar index vectors select one operand axis only. -/
def scatterTwoPartial (n0 n1 w0 w1 batches : Nat) (axis : Fin 2) : OrderedScatter.Plan 2 1 1 where
  operandShape := Fin.cases n0 (fun _ => n1)
  batchShape := fun _ => batches
  windowShape := Fin.cases w0 (fun _ => w1)
  indexAxes := ⟨#v[(axis.val : Int)], by intro component; fin_cases component; simp; omega⟩
  injective := fun first second _ => Subsingleton.elim first second

#eval show IO Unit from do
  let mut profile := 0
  for extent in List.range 4 do
    for window in List.range 4 do
      for batches in List.range 4 do
        for mode in List.range 8 do
          runScatterControl profile mode (scatterOnePlan extent window batches)
          profile := profile + 1
  for n0 in List.range 3 do
    for n1 in List.range 3 do
      for w0 in List.range 3 do
        for w1 in List.range 3 do
          for batches in List.range 3 do
            for mode in [2,5,7] do
              runScatterControl profile mode (scatterTwoPartial n0 n1 w0 w1 batches 0)
              profile := profile + 1
              runScatterControl profile mode (scatterTwoPartial n0 n1 w0 w1 batches 1)
              profile := profile + 1
              runScatterControl profile mode (scatterTwoPlan n0 n1 w0 w1 batches)
              profile := profile + 1
  for batches in List.range 4 do
    let plan : OrderedScatter.Plan 0 1 0 := {
      operandShape := Fin.elim0
      batchShape := fun _ => batches
      windowShape := Fin.elim0
      indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
      injective := fun axis => Fin.elim0 axis }
    runScatterControl profile 2 plan
    profile := profile + 1
  runScatterControl profile 2 (OrderedScatter.fullWindowPlan (Fin.elim0 : Shape 0)) true
  profile := profile + 1
  for extent in [0,1,3] do
    runScatterControl profile 2 (OrderedScatter.fullWindowPlan (fun _ : Fin 1 => extent)) true
    profile := profile + 1
  runScatterControl profile 2
    (OrderedScatter.fullWindowPlan (Fin.cases 2 (fun _ : Fin 1 => 2))) true
  profile := profile + 1
  runScatterControl profile 2
    (OrderedScatter.fullWindowPlan (Fin.cases 0 (fun _ : Fin 1 => 2))) true

/-- Finite actual binary32 Scatter translation controls, without assuming associativity. -/
def scatterFloatControl (base separate update : Nat) : IO Unit := do
  let shape : Shape 0 := Fin.elim0
  let point : Index shape := fun axis => Fin.elim0 axis
  let b : Binary32 := ExecFloat.Binary.ofNatBits base
  let x : Binary32 := ExecFloat.Binary.ofNatBits separate
  let u : Binary32 := ExecFloat.Binary.ofNatBits update
  let original := ExecFloat.add x
    (OrderedScatter.scatter (OrderedScatter.fullWindowPlan shape) ExecFloat.add
      (Tensor.constant b) (fun _ => Fin.elim0) (fun _ => Tensor.constant u) point)
  let transformed := OrderedScatter.scatter (OrderedScatter.fullWindowPlan shape) ExecFloat.add
    (Tensor.constant (ExecFloat.add x b)) (fun _ => Fin.elim0) (fun _ => Tensor.constant u) point
  IO.println s!"SCATTER_FLOAT base={base} separate={separate} update={update} source={ExecFloat.Binary.toNatBits original} target={ExecFloat.Binary.toNatBits transformed}"

#eval show IO Unit from do
  scatterFloatControl 0x4b800000 0xcb800000 0x3f800000
  scatterFloatControl 0x3f800000 0x40000000 0x40400000
  scatterFloatControl 0 0x80000000 0x80000000
  scatterFloatControl 1 2 3
