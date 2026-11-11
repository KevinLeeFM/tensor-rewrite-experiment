import TensorRewrite.Theory.ScatterBatchingCounterexample
import Mathlib.Tactic.FinCases

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Inspect actual raw coordinates, target slices and inherited word rewrite laws. -/
def batchingControl {components pairs : Nat} (profile : Nat) (scatter : ScatterLayout.Plan components)
    (plan : ScatterBatching.Plan scatter pairs)
    (layout : IndexVector.Layout components scatter.updateAxes.outputShape) : IO Unit := do
  let indices : Tensor layout.rawShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize layout.rawShape index).val % 4) - 1
  let updates : Tensor scatter.updateAxes.inputShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize scatter.updateAxes.inputShape index).val + 1)
  let base : Tensor scatter.operandShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize scatter.operandShape index).val + 2)
  let separate : Tensor scatter.operandShape Int := fun index =>
    3 * Int.ofNat (LinearIndex.linearize scatter.operandShape index).val + 1
  let events := ScatterBatching.entries scatter plan layout indices updates
  let decimal := ScatterBatching.run scatter plan layout (fun a b => 10 * a + b) base indices updates
  let canonical := OrderedScatter.scatter (ScatterBatching.canonicalPlan scatter)
    (fun a b => 10 * a + b) base
    (ScatterBatching.canonicalIndices plan (IndexVector.read layout indices))
    (ScatterLayout.adaptUpdates scatter updates)
  let ignored := ScatterIndices.scatter scatter layout (fun a b => 10 * a + b) base indices updates
  let front := IndexVector.Layout.here components scatter.updateAxes.outputShape
  let moved := ScatterBatching.run scatter plan front (fun a b => 10 * a + b) base
    (IndexVector.relayout layout front indices) updates
  let wordBase := Tensor.map (fun x : Int => BitVec.ofInt 4 x) base
  let wordSeparate := Tensor.map (fun x : Int => BitVec.ofInt 4 x) separate
  let wordUpdates := Tensor.map (fun x : Int => BitVec.ofInt 4 x) updates
  let wordLeft := ScatterBatching.run scatter plan layout (· + ·) wordBase indices wordUpdates
  let translated := Tensor.map₂ (· + ·) wordSeparate wordLeft
  let translationTarget := ScatterBatching.run scatter plan layout (· + ·)
    (Tensor.map₂ (· + ·) wordSeparate wordBase) indices wordUpdates
  let rightIndices := IndexVector.relayout layout front (Tensor.map (fun x => x + 1) indices)
  let rightUpdates := Tensor.map (fun x : Int => BitVec.ofInt 4 (2 * x + 1)) updates
  let pair := Tensor.map₂ (· + ·) wordLeft
    (ScatterBatching.run scatter plan front (· + ·) wordSeparate rightIndices rightUpdates)
  let nested := ScatterBatching.run scatter plan front (· + ·)
    (ScatterBatching.run scatter plan layout (· + ·) (Tensor.map₂ (· + ·) wordBase wordSeparate)
      indices wordUpdates) rightIndices rightUpdates
  let rawBatchAxes := Vector.ofFn fun pair =>
    (ScatterBatching.rawBatchAxis layout (plan.indexBatchAxes.decode pair)).val
  let vectorAxis : Int := match layout.vectorAxis? with | none => -1 | some axis => axis
  IO.println s!"BATCH_COUNT profile={profile} components={components} operand={(Vector.ofFn scatter.operandShape).toList} index_raw={(Vector.ofFn layout.rawShape).toList} vector_axis={vectorAxis} update_raw={(Vector.ofFn scatter.updateAxes.inputShape).toList} batch={(Vector.ofFn scatter.updateAxes.outputShape).toList} compact={(Vector.ofFn (ReductionFiber.shape scatter.updateAxes)).toList} full={(Vector.ofFn scatter.windows.fullShape).toList} index_axes={scatter.indexAxes.values.toList} operand_pairs={plan.operandAxes.values.toList} index_pairs={plan.indexBatchAxes.values.toList} raw_index_pairs={rawBatchAxes.toList} events={events.length}"
  for (entry, ordinal) in events.zipIdx do
    let target := match entry.target with
      | none => (-1 : Int)
      | some index => (LinearIndex.linearize scatter.operandShape index).val
    IO.println s!"BATCH_EVENT profile={profile} event={ordinal} target={target} value={entry.value}"
  for position in List.finRange (LinearIndex.elementCount scatter.operandShape) do
    let index := LinearIndex.delinearize scatter.operandShape position
    IO.println s!"BATCH_VALUE profile={profile} output={position.val} decimal={decimal index} canonical={canonical index} ignored={ignored index} moved={moved index} translated={(translated index).toNat} translation_target={(translationTarget index).toNat} pair={(pair index).toNat} nested={(nested index).toNat}"

/-- Iterate actual index-vector representations without altering their batch interpretation. -/
def batchingLayouts {components pairs : Nat} (start : Nat) (scatter : ScatterLayout.Plan components)
    (plan : ScatterBatching.Plan scatter pairs)
    (layouts : List (IndexVector.Layout components scatter.updateAxes.outputShape)) : IO Nat := do
  let mut profile := start
  for layout in layouts do
    batchingControl profile scatter plan layout
    profile := profile + 1
  return profile

/-- One operand batch dimension and an optionally interleaved window update axis. -/
def batchOne (components extent window batch : Nat) (small : components ≤ 1) (reverse : Bool) : ScatterLayout.Plan components :=
  if reverse then {
    updateAxes := .reduce window (.keep batch .scalar)
    windows := .insert (.keep window .scalar)
    operandShape := Fin.cases batch (fun _ => extent)
    indexAxes := ⟨Vector.ofFn (fun _ => 1), by
      intro component
      change 0 ≤ (Vector.ofFn (fun _ : Fin components => (1 : Int)))[component] ∧
        (Vector.ofFn (fun _ : Fin components => (1 : Int)))[component] < 2
      simp⟩
    injective := by intro a b _; omega
  } else {
    updateAxes := .keep batch (.reduce window .scalar)
    windows := .insert (.keep window .scalar)
    operandShape := Fin.cases batch (fun _ => extent)
    indexAxes := ⟨Vector.ofFn (fun _ => 1), by
      intro component
      change 0 ≤ (Vector.ofFn (fun _ : Fin components => (1 : Int)))[component] ∧
        (Vector.ofFn (fun _ : Fin components => (1 : Int)))[component] < 2
      simp⟩
    injective := by intro a b _; omega
  }

/-- Pair the inserted first operand axis with the original single index-batch axis. -/
def pairOne (components extent window batch : Nat) (small : components ≤ 1) (reverse : Bool) :
    ScatterBatching.Plan (batchOne components extent window batch small reverse) 1 := by
  cases reverse <;> exact {
    operandAxes := ⟨#v[0], by dsimp [batchOne, ScatterLayout.WindowEmbedding.fullRank]; decide⟩
    indexBatchAxes := ⟨#v[0], by dsimp [batchOne, Reduction.Plan.outputRank]; decide⟩
    operand_injective := fun a b _ => Subsingleton.elim a b
    index_injective := fun a b _ => Subsingleton.elim a b
    extents := by intro pair; fin_cases pair; rfl
    inserted := by intro pair; fin_cases pair; rfl
    disjoint := by intro component pair; fin_cases pair; simp [batchOne, IndexMaps.BroadcastAxes.decode]
  }

/-- Two actual index-batch axes, one compact window axis and either original or swapped slices. -/
def batchTwo (b0 b1 extent window : Nat) (mode : Fin 3) : ScatterLayout.Plan 1 where
  updateAxes := .keep b0 (.reduce window (.keep b1 .scalar))
  windows := .insert (.insert (.keep window .scalar))
  operandShape := Fin.cases (if mode.val = 1 then b1 else b0)
    (Fin.cases (if mode.val = 1 then b0 else b1) (fun _ => extent))
  indexAxes := ⟨#v[2], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun a b _ => Subsingleton.elim a b

/-- Allow an unsorted operand pairing, or the same pairing with both arrays simultaneously reordered. -/
def pairTwo (b0 b1 extent window : Nat) (mode : Fin 3) :
    ScatterBatching.Plan (batchTwo b0 b1 extent window mode) 2 where
  operandAxes := ⟨if mode.val = 0 then #v[0,1] else #v[1,0], by
    dsimp [batchTwo, ScatterLayout.WindowEmbedding.fullRank]; fin_cases mode <;> decide⟩
  indexBatchAxes := ⟨if mode.val = 2 then #v[1,0] else #v[0,1], by
    dsimp [batchTwo, Reduction.Plan.outputRank]; fin_cases mode <;> decide⟩
  operand_injective := by
    intro a b same
    fin_cases mode <;> fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]
  index_injective := by
    intro a b same
    fin_cases mode <;> fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]
  extents := by intro pair; fin_cases mode <;> fin_cases pair <;> rfl
  inserted := by intro pair; fin_cases mode <;> fin_cases pair <;> rfl
  disjoint := by
    intro component pair
    fin_cases mode <;> fin_cases component <;> fin_cases pair <;>
      simp [batchTwo, IndexMaps.BroadcastAxes.decode]

/-- Only one of the two original batch axes selects an operand slice; the other may overlap. -/
def batchPartial (b0 b1 extent window : Nat) (selected : Fin 2) : ScatterLayout.Plan 1 where
  updateAxes := .keep b0 (.reduce window (.keep b1 .scalar))
  windows := .insert (.keep window .scalar)
  operandShape := Fin.cases (if selected.val = 0 then b0 else b1) (fun _ => extent)
  indexAxes := ⟨#v[1], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun a b _ => Subsingleton.elim a b

/-- Select either actual index-batch dimension, including a nonleading one. -/
def pairPartial (b0 b1 extent window : Nat) (selected : Fin 2) :
    ScatterBatching.Plan (batchPartial b0 b1 extent window selected) 1 where
  operandAxes := ⟨#v[0], by dsimp [batchPartial, ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  indexBatchAxes := ⟨#v[(selected.val : Int)], by
    intro axis; fin_cases axis
    have bound := selected.isLt
    change 0 ≤ (selected.val : Int) ∧ (selected.val : Int) < 2
    omega⟩
  operand_injective := fun a b _ => Subsingleton.elim a b
  index_injective := fun a b _ => Subsingleton.elim a b
  extents := by intro pair; fin_cases selected <;> fin_cases pair <;> rfl
  inserted := by intro pair; fin_cases pair; rfl
  disjoint := by
    intro component pair
    fin_cases component; fin_cases pair
    simp [batchPartial, IndexMaps.BroadcastAxes.decode]

/-- A point update for every two-dimensional batch, with an explicit empty vector. -/
def batchZeroTwo (b0 b1 : Nat) (reverse : Bool) : ScatterLayout.Plan 0 where
  updateAxes := .keep b0 (.keep b1 .scalar)
  windows := .insert (.insert .scalar)
  operandShape := Fin.cases (if reverse then b1 else b0) (fun _ => if reverse then b0 else b1)
  indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  injective := fun axis => Fin.elim0 axis

/-- Both point-update operand axes are selected by the two original batch coordinates. -/
def pairZeroTwo (b0 b1 : Nat) (reverse : Bool) :
    ScatterBatching.Plan (batchZeroTwo b0 b1 reverse) 2 where
  operandAxes := ⟨if reverse then #v[1,0] else #v[0,1], by
    dsimp [batchZeroTwo, ScatterLayout.WindowEmbedding.fullRank]; cases reverse <;> decide⟩
  indexBatchAxes := ⟨#v[0,1], by dsimp [batchZeroTwo, Reduction.Plan.outputRank]; decide⟩
  operand_injective := by
    intro a b same
    cases reverse <;> fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]
  index_injective := by
    intro a b same
    fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]
  extents := by intro pair; cases reverse <;> fin_cases pair <;> rfl
  inserted := by intro pair; cases reverse <;> fin_cases pair <;> rfl
  disjoint := fun component => Fin.elim0 component

/-- Ordinary one-axis Scatter is retained when the pairing arrays are empty. -/
def batchNone (extent window batch : Nat) : ScatterLayout.Plan 1 where
  updateAxes := .keep batch (.reduce window .scalar)
  windows := .keep window .scalar
  operandShape := fun _ => extent
  indexAxes := ⟨#v[0], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := fun a b _ => Subsingleton.elim a b

/-- Empty pair arrays impose no artificial restrictions on the underlying Scatter profile. -/
def noPairing {components : Nat} (scatter : ScatterLayout.Plan components) :
    ScatterBatching.Plan scatter 0 where
  operandAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  indexBatchAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
  operand_injective := fun axis => Fin.elim0 axis
  index_injective := fun axis => Fin.elim0 axis
  extents := fun axis => Fin.elim0 axis
  inserted := fun axis => Fin.elim0 axis
  disjoint := fun _ axis => Fin.elim0 axis

/-- Both unsorted spatial index components remain disjoint from the operand batch axis. -/
def batchSpatialTwo (extent window batch : Nat) : ScatterLayout.Plan 2 where
  updateAxes := .keep batch (.reduce window (.reduce window .scalar))
  windows := .insert (.keep window (.keep window .scalar))
  operandShape := Fin.cases batch (fun _ => extent)
  indexAxes := ⟨#v[2,1], by dsimp [ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  injective := by
    intro a b same
    fin_cases a <;> fin_cases b <;> simp_all [IndexMaps.BroadcastAxes.decode]

/-- Pairing does not alter either original spatial index-vector component. -/
def pairSpatialTwo (extent window batch : Nat) :
    ScatterBatching.Plan (batchSpatialTwo extent window batch) 1 where
  operandAxes := ⟨#v[0], by dsimp [batchSpatialTwo, ScatterLayout.WindowEmbedding.fullRank]; decide⟩
  indexBatchAxes := ⟨#v[0], by dsimp [batchSpatialTwo, Reduction.Plan.outputRank]; decide⟩
  operand_injective := fun a b _ => Subsingleton.elim a b
  index_injective := fun a b _ => Subsingleton.elim a b
  extents := by intro pair; fin_cases pair; rfl
  inserted := by intro pair; fin_cases pair; rfl
  disjoint := by
    intro component pair
    fin_cases component <;> fin_cases pair <;> simp [batchSpatialTwo, IndexMaps.BroadcastAxes.decode]

#eval show IO Unit from do
  let scalar : Shape 0 := Fin.elim0
  let mut profile := 0
  for batch in List.range 3 do
    for extent in List.range 3 do
      for window in List.range 3 do
        for reverse in [false,true] do
          let one := batchOne 1 extent window batch (by decide) reverse
          let onePair := pairOne 1 extent window batch (by decide) reverse
          let back : IndexVector.Layout 1 one.updateAxes.outputShape := by
            cases reverse <;> change IndexVector.Layout 1 (Fin.cases batch scalar) <;>
              exact .batch batch (.here 1 scalar)
          profile ← batchingLayouts profile one onePair
            [.here 1 one.updateAxes.outputShape, back, .implicit one.updateAxes.outputShape]
          let zero := batchOne 0 extent window batch (by decide) reverse
          let zeroPair := pairOne 0 extent window batch (by decide) reverse
          let back : IndexVector.Layout 0 zero.updateAxes.outputShape := by
            cases reverse <;> change IndexVector.Layout 0 (Fin.cases batch scalar) <;>
              exact .batch batch (.here 0 scalar)
          profile ← batchingLayouts profile zero zeroPair [.here 0 zero.updateAxes.outputShape,back]
  for b0 in List.range 3 do
    for b1 in List.range 3 do
      for extent in List.range 3 do
        for window in List.range 3 do
          for mode in List.finRange 3 do
            let scatter := batchTwo b0 b1 extent window mode
            let plan := pairTwo b0 b1 extent window mode
            let middle : IndexVector.Layout 1 scatter.updateAxes.outputShape := by
              change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
              exact .batch b0 (.here 1 (Fin.cases b1 scalar))
            let back : IndexVector.Layout 1 scatter.updateAxes.outputShape := by
              change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
              exact .batch b0 (.batch b1 (.here 1 scalar))
            profile ← batchingLayouts profile scatter plan
              [.here 1 scatter.updateAxes.outputShape,middle,back,.implicit scatter.updateAxes.outputShape]
          for selected in List.finRange 2 do
            let scatter := batchPartial b0 b1 extent window selected
            let plan := pairPartial b0 b1 extent window selected
            let middle : IndexVector.Layout 1 scatter.updateAxes.outputShape := by
              change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
              exact .batch b0 (.here 1 (Fin.cases b1 scalar))
            let back : IndexVector.Layout 1 scatter.updateAxes.outputShape := by
              change IndexVector.Layout 1 (Fin.cases b0 (Fin.cases b1 scalar))
              exact .batch b0 (.batch b1 (.here 1 scalar))
            profile ← batchingLayouts profile scatter plan
              [.here 1 scatter.updateAxes.outputShape,middle,back,.implicit scatter.updateAxes.outputShape]
  for b0 in List.range 3 do
    for b1 in List.range 3 do
      for reverse in [false,true] do
        let scatter := batchZeroTwo b0 b1 reverse
        let plan := pairZeroTwo b0 b1 reverse
        let back : IndexVector.Layout 0 scatter.updateAxes.outputShape := by
          change IndexVector.Layout 0 (Fin.cases b0 (Fin.cases b1 scalar))
          exact .batch b0 (.batch b1 (.here 0 scalar))
        profile ← batchingLayouts profile scatter plan [.here 0 scatter.updateAxes.outputShape,back]
  for extent in List.range 3 do
    for window in List.range 3 do
      for batch in List.range 3 do
        let scatter := batchNone extent window batch
        profile ← batchingLayouts profile scatter (noPairing scatter)
          [.here 1 scatter.updateAxes.outputShape,.implicit scatter.updateAxes.outputShape]
  let scatter : ScatterLayout.Plan 0 := {
    updateAxes := .scalar
    windows := .scalar
    operandShape := Fin.elim0
    indexAxes := ⟨#v[], fun axis => Fin.elim0 axis⟩
    injective := fun axis => Fin.elim0 axis
  }
  batchingControl profile scatter (noPairing scatter) (.here 0 scatter.updateAxes.outputShape)
  profile := profile + 1
  for extent in List.range 3 do
    for window in List.range 3 do
      for batch in List.range 3 do
        let scatter := batchSpatialTwo extent window batch
        let plan := pairSpatialTwo extent window batch
        let back : IndexVector.Layout 2 scatter.updateAxes.outputShape := by
          change IndexVector.Layout 2 (Fin.cases batch scalar)
          exact .batch batch (.here 2 scalar)
        profile ← batchingLayouts profile scatter plan [.here 2 scatter.updateAxes.outputShape,back]
