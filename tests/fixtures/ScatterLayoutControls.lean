import TensorRewrite.Theory.ScatterLayoutCounterexample
import Mathlib.Tactic.FinCases

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Report which actual raw update axes are windows rather than batch axes. -/
def updateMask : Reduction.Plan → List Nat
  | .scalar => []
  | .keep _ tail => 0 :: updateMask tail
  | .reduce _ tail => 1 :: updateMask tail

/-- Report the actual singleton insertion positions in the full operand window. -/
def insertionMask : {rank : Nat} → {shape : Shape rank} →
    ScatterLayout.WindowEmbedding shape → List Nat
  | _, _, .scalar => []
  | _, _, .insert tail => 1 :: insertionMask tail
  | _, _, .keep _ tail => 0 :: insertionMask tail

/-- Compare actual raw-input events/results, the derived full-rank adapter and raw storage order. -/
def layoutControl {indexSize : Nat} (profile : Nat) (plan : ScatterLayout.Plan indexSize) :
    IO Unit := do
  let indices : Tensor plan.updateAxes.outputShape (Fin indexSize → Int) := fun batch component =>
    Int.ofNat (((LinearIndex.linearize plan.updateAxes.outputShape batch).val + component.val) % 4) - 1
  let updates : Tensor plan.updateAxes.inputShape Int := fun raw =>
    Int.ofNat ((LinearIndex.linearize plan.updateAxes.inputShape raw).val + 1)
  let base : Tensor plan.operandShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize plan.operandShape index).val + 2)
  let separate : Tensor plan.operandShape Int := fun index =>
    3 * Int.ofNat (LinearIndex.linearize plan.operandShape index).val + 1
  let events := ScatterLayout.entries plan indices updates
  let decimal := ScatterLayout.scatter plan (fun a b => 10 * a + b) base indices updates
  let canonical := OrderedScatter.scatter plan.toOrdered (fun a b => 10 * a + b) base indices
    (ScatterLayout.adaptUpdates plan updates)
  let storage := OrderedScatter.run (fun a b => 10 * a + b) base
    (ScatterLayout.storageEntries plan indices updates)
  let source := Tensor.map₂ (· + ·) separate
    (ScatterLayout.scatter plan (· + ·) base indices updates)
  let target := ScatterLayout.scatter plan (· + ·) (Tensor.map₂ (· + ·) separate base)
    indices updates
  let wordBase := Tensor.map (fun x : Int => BitVec.ofInt 4 x) base
  let wordSeparate := Tensor.map (fun x : Int => BitVec.ofInt 4 x) separate
  let wordUpdates := Tensor.map (fun x : Int => BitVec.ofInt 4 x) updates
  let wordSource := Tensor.map₂ (· + ·) wordSeparate
    (ScatterLayout.scatter plan (· + ·) wordBase indices wordUpdates)
  let wordTarget := ScatterLayout.scatter plan (· + ·)
    (Tensor.map₂ (· + ·) wordSeparate wordBase) indices wordUpdates
  let coupledBase : Tensor plan.operandShape (Fin 2 → Int) := fun index component =>
    if component.val = 0 then base index else -(base index)
  let coupledUpdates : Tensor plan.updateAxes.inputShape (Fin 2 → Int) := fun raw component =>
    if component.val = 0 then updates raw else 1 - updates raw
  let coupledOp (first second : Fin 2 → Int) (component : Fin 2) : Int :=
    if component.val = 0 then first 0 + second 1 else first 0 + first 1 - second 0
  let coupled := ScatterLayout.scatter plan coupledOp coupledBase indices coupledUpdates
  let coupledCanonical := OrderedScatter.scatter plan.toOrdered coupledOp coupledBase indices
    (ScatterLayout.adaptUpdates plan coupledUpdates)
  IO.println s!"LAYOUT_COUNT profile={profile} operand={(Vector.ofFn plan.operandShape).toList} raw={(Vector.ofFn plan.updateAxes.inputShape).toList} batch={(Vector.ofFn plan.updateAxes.outputShape).toList} compact={(Vector.ofFn (ReductionFiber.shape plan.updateAxes)).toList} full={(Vector.ofFn plan.windows.fullShape).toList} update_mask={updateMask plan.updateAxes} insert_mask={insertionMask plan.windows} axes={plan.indexAxes.values.toList} events={events.length}"
  for (entry, ordinal) in events.zipIdx do
    let target := match entry.target with
      | none => (-1 : Int)
      | some index => (LinearIndex.linearize plan.operandShape index).val
    IO.println s!"LAYOUT_EVENT profile={profile} event={ordinal} target={target} value={entry.value}"
  for position in List.finRange (LinearIndex.elementCount plan.operandShape) do
    let index := LinearIndex.delinearize plan.operandShape position
    IO.println s!"LAYOUT_VALUE profile={profile} output={position.val} decimal={decimal index} canonical={canonical index} storage={storage index} source={source index} target={target index} word_source={(wordSource index).toNat} word_target={(wordTarget index).toNat} coupled={(Vector.ofFn (coupled index)).toList} coupled_canonical={(Vector.ofFn (coupledCanonical index)).toList}"

/-- A raw batch/window tensor with no inserted operand dimension. -/
def layoutBatchWindow (extent window batch : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .keep batch (.reduce window .scalar)
  windows := .keep window .scalar
  operandShape := fun _ => extent
  indexAxes := ⟨#v[0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- The actual window/batch dimension order, without an inserted operand dimension. -/
def layoutWindowBatch (extent window batch : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .reduce window (.keep batch .scalar)
  windows := .keep window .scalar
  operandShape := fun _ => extent
  indexAxes := ⟨#v[0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- Insert one leading window dimension; the signed index vector addresses both operand axes. -/
def layoutInsertFront (extent window batch : Nat) : ScatterLayout.Plan 2 where
  updateAxes := .reduce window (.keep batch .scalar)
  windows := .insert (.keep window .scalar)
  operandShape := Fin.cases 2 (fun _ => extent)
  indexAxes := ⟨#v[1, 0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := by
    intro a b same
    fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]

/-- Insert one trailing window dimension, omitted from the actual index-axis map. -/
def layoutInsertBack (extent window batch : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .keep batch (.reduce window .scalar)
  windows := .keep window (.insert .scalar)
  operandShape := Fin.cases extent (fun _ => 2)
  indexAxes := ⟨#v[0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- Rank-four interleaved update tensor with two batch axes and a middle inserted operand axis. -/
def layoutMultiple (b0 b1 w0 w1 : Nat) : ScatterLayout.Plan 2 where
  updateAxes := .keep b0 (.reduce w0 (.keep b1 (.reduce w1 .scalar)))
  windows := .keep w0 (.insert (.keep w1 .scalar))
  operandShape := fun _ => 2
  indexAxes := ⟨#v[2, 0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := by
    intro a b same
    fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]

#eval show IO Unit from do
  let mut profile := 0
  for extent in List.range 3 do
    for window in List.range 3 do
      for batch in List.range 3 do
        layoutControl profile (layoutBatchWindow extent window batch)
        profile := profile + 1
        layoutControl profile (layoutWindowBatch extent window batch)
        profile := profile + 1
        layoutControl profile (layoutInsertFront extent window batch)
        profile := profile + 1
        layoutControl profile (layoutInsertBack extent window batch)
        profile := profile + 1
  for b0 in List.range 3 do
    for b1 in List.range 3 do
      for w0 in List.range 3 do
        for w1 in List.range 3 do
          layoutControl profile (layoutMultiple b0 b1 w0 w1)
          profile := profile + 1
  for batch in List.range 4 do
    let scalar : ScatterLayout.Plan 0 := {
      updateAxes := .keep batch .scalar
      windows := .scalar
      operandShape := Fin.elim0
      indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
      injective := fun axis => Fin.elim0 axis
    }
    layoutControl profile scalar
    profile := profile + 1
    let point : ScatterLayout.Plan 2 := {
      updateAxes := .keep batch .scalar
      windows := .insert (.insert .scalar)
      operandShape := fun _ => 2
      indexAxes := ⟨#v[1, 0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
      injective := by
        intro a b same
        fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]
    }
    layoutControl profile point
    profile := profile + 1
