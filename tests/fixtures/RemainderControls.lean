import TensorRewrite.Pilot.LinearIndex
import TensorRewrite.Theory.RemainderCounterexamples
import TensorRewrite.Theory.UniformSumCounterexample

open TensorRewrite TensorRewrite.Pilot TensorRewrite.Theory FloatLib.Floats

/-- Evaluate actual bounded Iota tensors, both addend orientations and each range contract. -/
def runRemainderIota {rank : Nat} (profile width : Nat) (shape : Shape rank) (axis : Fin rank)
    (denominator : Nat) : IO Unit := do
  let divisor := BitVec.ofNat width denominator
  let values := Remainder.iota shape axis width
  let outputs := List.finRange (LinearIndex.elementCount shape)
  let unsignedFits := outputs.all fun position =>
    let index := LinearIndex.delinearize shape position
    decide ((index axis).val + divisor.toNat < 2 ^ width)
  let signedFits := !divisor.msb && outputs.all fun position =>
    let index := LinearIndex.delinearize shape position
    decide (2 * ((index axis).val + divisor.toNat) < 2 ^ width)
  IO.println s!"REM_IOTA_COUNT profile={profile} width={width} shape={(Vector.ofFn shape).toList} axis={axis.val} divisor={divisor.toNat} outputs={outputs.length} unsigned_bound={decide (shape axis ≤ divisor.toNat)} signed_bound={!divisor.msb && decide (shape axis ≤ divisor.toNat)} unsigned_offset={unsignedFits} signed_offset={signedFits}"
  for position in outputs do
    let index := LinearIndex.delinearize shape position
    let value := values index
    IO.println s!"REM_IOTA profile={profile} output={position.val} coordinate={(index axis).val} value={value.toNat} signed_value={value.toInt} unsigned={(value % divisor).toNat} signed={(value.srem divisor).toInt} unsigned_rhs={((value + divisor) % divisor).toNat} unsigned_lhs={((divisor + value) % divisor).toNat} signed_rhs={((value + divisor).srem divisor).toInt} signed_lhs={((divisor + value).srem divisor).toInt}"

/-- All small finite shapes, including zero axes. -/
def remainderShapes : (rank : Nat) → List (Shape rank)
  | 0 => [Fin.elim0]
  | rank + 1 => (List.range 3).flatMap fun head =>
    (remainderShapes rank).map fun tail => Fin.cases head tail

#eval show IO Unit from do
  for width in List.range 7 do
    for x in List.range (2 ^ width) do
      for y in List.range (2 ^ width) do
        let value := BitVec.ofNat width x
        let divisor := BitVec.ofNat width y
        IO.println s!"REM_PAIR width={width} x={x} y={y} unsigned={(value % divisor).toNat} signed={(value.srem divisor).toInt} unsigned_nested={((value % divisor) % divisor).toNat} signed_nested={((value.srem divisor).srem divisor).toInt} unsigned_mask={(value &&& (divisor - 1)).toNat} signed_mask={(Remainder.signedMask value divisor).toInt} unsigned_offset={((value + divisor) % divisor).toNat} signed_offset={((value + divisor).srem divisor).toInt}"
  for x in List.range 19 do
    for y in List.range 19 do
      let value := Int.ofNat x - 9
      let divisor := Int.ofNat y - 9
      IO.println s!"REM_INT x={value} y={divisor} remainder={Remainder.integer value divisor} nested={Remainder.integer (Remainder.integer value divisor) divisor}"
  let mut profile := 0
  for width in [0, 1, 2, 4] do
    for rank in [1, 2, 3] do
      for shape in remainderShapes rank do
        for axis in List.finRange rank do
          for divisor in List.range (2 ^ width) do
            runRemainderIota profile width shape axis divisor
            profile := profile + 1
  runRemainderIota profile 4 (fun _ : Fin 1 => 8) 0 3
  profile := profile + 1
  runRemainderIota profile 4 (fun _ : Fin 1 => 8) 0 10
  profile := profile + 1
  runRemainderIota profile 4 (fun _ : Fin 1 => 6) 0 3
  profile := profile + 1
  runRemainderIota profile 4 (Fin.cases 0 (fun _ : Fin 1 => 8)) 1 10

/-- Compare actual ordered uniform binary32 folds against multiplication by exact count encodings. -/
def runUniformControl (word count countWord : Nat) : IO Unit := do
  let value : Binary32 := ExecFloat.Binary.ofNatBits word
  let result := (List.replicate count value).foldl ExecFloat.add (ExecFloat.Binary.ofNatBits 0)
  let target := ExecFloat.mul value (ExecFloat.Binary.ofNatBits countWord)
  IO.println s!"REM_UNIFORM word={word} count={count} count_word={countWord} fold={ExecFloat.Binary.toNatBits result} product={ExecFloat.Binary.toNatBits target}"

#eval show IO Unit from do
  for word in [0, 0x80000000, 0x3dcccccd, 1, 0x3f800000] do
    for (count, countWord) in [(1, 0x3f800000), (2, 0x40000000), (3, 0x40400000),
        (7, 0x40e00000), (8, 0x41000000), (10, 0x41200000)] do
      runUniformControl word count countWord
