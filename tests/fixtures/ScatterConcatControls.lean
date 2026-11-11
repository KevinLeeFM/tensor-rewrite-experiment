import TensorRewrite.Theory.ScatterConcatProof

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory

/-- Check actual input concatenation, event order and arbitrary/word reducers. -/
def concatControl {rank oldBatchRank tailRank indexSize : Nat} (profile first second : Nat)
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) (tail : Shape tailRank) :
    IO Unit := do
  let leftShape := ScatterConcat.batchShape first tail
  let rightShape := ScatterConcat.batchShape second tail
  let leftPlan := ScatterConcat.rebatch geometry leftShape
  let rightPlan := ScatterConcat.rebatch geometry rightShape
  let joinedPlan := ScatterConcat.rebatch geometry (ScatterConcat.batchShape (first + second) tail)
  let makeIndices (count side : Nat) :
      Tensor (ScatterConcat.batchShape count tail) (Fin indexSize → Int) := fun batch component =>
    Int.ofNat (((LinearIndex.linearize (ScatterConcat.batchShape count tail) batch).val +
      2 * side + component.val) % 5) - 2
  let makeUpdates (count side : Nat) :
      Tensor (ScatterConcat.batchShape count tail) (Tensor geometry.windowShape Int) :=
    fun batch window => Int.ofNat (1 + 13 * side +
      10 * (LinearIndex.linearize (ScatterConcat.batchShape count tail) batch).val +
      (LinearIndex.linearize geometry.windowShape window).val)
  let leftIndices := makeIndices first 0
  let rightIndices := makeIndices second 1
  let leftUpdates := makeUpdates first 0
  let rightUpdates := makeUpdates second 1
  let joinedIndices := ScatterConcat.concatenate tail leftIndices rightIndices
  let joinedUpdates := ScatterConcat.concatenate tail leftUpdates rightUpdates
  let events := OrderedScatter.entries joinedPlan joinedIndices joinedUpdates
  let base : Tensor geometry.operandShape Int := fun index =>
    Int.ofNat ((LinearIndex.linearize geometry.operandShape index).val + 2)
  let other : Tensor geometry.operandShape Int := fun index =>
    3 * Int.ofNat (LinearIndex.linearize geometry.operandShape index).val + 1
  let decimal := OrderedScatter.scatter joinedPlan (fun a b => 10 * a + b) base
    joinedIndices joinedUpdates
  let nested := OrderedScatter.scatter rightPlan (fun a b => 10 * a + b)
    (OrderedScatter.scatter leftPlan (fun a b => 10 * a + b) base leftIndices leftUpdates)
    rightIndices rightUpdates
  let source := Tensor.map₂ (· + ·)
    (OrderedScatter.scatter leftPlan (· + ·) base leftIndices leftUpdates)
    (OrderedScatter.scatter rightPlan (· + ·) other rightIndices rightUpdates)
  let target := OrderedScatter.scatter joinedPlan (· + ·) (Tensor.map₂ (· + ·) base other)
    joinedIndices joinedUpdates
  let wordBase := Tensor.map (fun x : Int => BitVec.ofInt 4 x) base
  let wordOther := Tensor.map (fun x : Int => BitVec.ofInt 4 x) other
  let wordLeft := fun batch => Tensor.map (fun x : Int => BitVec.ofInt 4 x) (leftUpdates batch)
  let wordRight := fun batch => Tensor.map (fun x : Int => BitVec.ofInt 4 x) (rightUpdates batch)
  let wordSource := Tensor.map₂ (· + ·)
    (OrderedScatter.scatter leftPlan (· + ·) wordBase leftIndices wordLeft)
    (OrderedScatter.scatter rightPlan (· + ·) wordOther rightIndices wordRight)
  let wordTarget := OrderedScatter.scatter joinedPlan (· + ·)
    (Tensor.map₂ (· + ·) wordBase wordOther) joinedIndices
    (ScatterConcat.concatenate tail wordLeft wordRight)
  IO.println s!"CONCAT_COUNT profile={profile} operand={(Vector.ofFn geometry.operandShape).toList} window={(Vector.ofFn geometry.windowShape).toList} axes={geometry.indexAxes.values.toList} first={first} second={second} tail={(Vector.ofFn tail).toList} events={events.length}"
  for (entry, ordinal) in events.zipIdx do
    let target := match entry.target with
      | none => (-1 : Int)
      | some index => (LinearIndex.linearize geometry.operandShape index).val
    IO.println s!"CONCAT_EVENT profile={profile} event={ordinal} target={target} value={entry.value}"
  for position in List.finRange (LinearIndex.elementCount geometry.operandShape) do
    let index := LinearIndex.delinearize geometry.operandShape position
    IO.println s!"CONCAT_VALUE profile={profile} output={position.val} decimal={decimal index} nested={nested index} source={source index} target={target index} word_source={(wordSource index).toNat} word_target={(wordTarget index).toNat}"

/-- Include scalar, empty and higher-rank trailing batches. -/
def concatTails {rank oldBatchRank indexSize : Nat} (profile : Nat)
    (geometry : OrderedScatter.Plan rank oldBatchRank indexSize) : IO Nat := do
  let mut current := profile
  for first in List.range 3 do
    for second in List.range 3 do
      concatControl current first second geometry (fun axis => Fin.elim0 axis)
      current := current + 1
      concatControl current first second geometry (fun _ : Fin 1 => 0)
      current := current + 1
      concatControl current first second geometry (fun _ : Fin 1 => 2)
      current := current + 1
      concatControl current first second geometry (fun axis : Fin 2 => if axis.val = 0 then 2 else 0)
      current := current + 1
      concatControl current first second geometry (fun _ : Fin 2 => 2)
      current := current + 1
  return current

/-- Exercise varying operand/windows, omitted/permuted index axes and a scalar operand. -/
def main : IO Unit := do
  let mut profile := 0
  for extent in List.range 3 do
    for window in List.range 3 do
      let geometry : OrderedScatter.Plan 1 0 1 := {
        operandShape := fun _ => extent
        batchShape := Fin.elim0
        windowShape := fun _ => window
        indexAxes := ⟨#v[0], by decide +revert⟩
        injective := fun a b _ => Subsingleton.elim a b
      }
      profile ← concatTails profile geometry
  for window in [1, 2] do
    let geometry : OrderedScatter.Plan 2 0 2 := {
      operandShape := fun _ => 2
      batchShape := Fin.elim0
      windowShape := fun _ => window
      indexAxes := ⟨#v[1, 0], by decide +revert⟩
      injective := by decide +revert
    }
    profile ← concatTails profile geometry
  let geometry := OrderedScatter.fullWindowPlan (fun axis => Fin.elim0 axis)
  discard <| concatTails profile geometry

#eval main
