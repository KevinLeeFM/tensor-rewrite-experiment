import TensorRewrite.Theory.ConcatenationCounterexamples
import TensorRewrite.Theory.OrderedCoordinates
import TensorRewrite.Libraries.FloatingPoint
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

open TensorRewrite.Pilot TensorRewrite.Theory.Concatenation TensorRewrite.Theory FloatLib.Floats

private def csv (values : List Nat) : String :=
  if values.isEmpty then "-" else String.intercalate "," (values.map toString)

private def coordinates {rank : Nat} {shape : Shape rank} (index : Index shape) : String :=
  csv ((List.finRange rank).map fun axis => (index axis).val)

private def cases : Nat → List (List Nat)
  | 0 => [[]]
  | length + 1 => [0, 1, 2].flatMap fun extent => (cases length).map (extent :: ·)

private def countCases : List (List Nat) :=
  (List.range 4).flatMap cases ++ [[0, 1, 0, 2], [1, 2, 1, 2]]

private def operandBlocks {rank : Nat} {α : Type} (frame : Frame rank) (convert : Int → α)
    (counts : List Nat) : List (Block frame α) :=
  counts.zipIdx.map fun (extent, ordinal) => ⟨extent, fun index =>
    let others := (List.finRange rank).foldl (fun sum axis =>
      if axis = frame.axis then sum else sum + (axis.val + 1) * (index axis).val) 0
    convert (Int.ofNat (200 * ordinal + 10 * (frame.position index).val + others) - 17)⟩

private def concatControls {α : Type} (track : String) (convert : Int → α)
    (encode : α → Int) (rank : Nat) : IO Unit := do
  for axis in List.finRange rank do
    for other in [0, 1, 2] do
      let frame : Frame rank := ⟨fun _ => other, axis⟩
      for counts in countCases do
        let blocks := operandBlocks frame convert counts
        let selected := filterEmpty blocks
        let shape := frame.shape (total blocks)
        let raw := csv counts
        let kept := csv (selected.map Block.extent)
        let outputShape := csv ((List.finRange rank).map shape)
        IO.println s!"CAT_PROFILE track={track} rank={rank} axis={axis.val} other={other} counts={raw} shape={outputShape} kept={kept} kept_total={total selected}"
        let groups := [blocks.take 1, blocks.drop 1]
        have flattenEq : groups.flatten = blocks := by
          simp only [groups, List.flatten_cons, List.flatten_nil, List.append_nil]
          exact List.take_append_drop 1 blocks
        have groupedTotal : total (groups.map pack) = total blocks := by
          rw [total_flatten, flattenEq]
        let grouped := frame.castTensor groupedTotal (concatenate (groups.map pack))
        let zeroFiltered := frame.castTensor (total_filterZero blocks) (concatenate (filterZero blocks))
        for index in OrderedCoordinates.enumerate shape do
          have emptyTotal : total (filterEmpty blocks) = total blocks := by
            obtain ⟨live, _, nonempty⟩ := readAt_live_operand blocks (frame.rest index)
              (frame.position index).val (frame.position index).isLt
            exact total_filterEmpty blocks live nonempty
          let actuallyFiltered := frame.castTensor emptyTotal (concatenate (filterEmpty blocks))
          let source := encode (concatenate blocks index)
          let zero := encode (zeroFiltered index)
          let nested := encode (grouped index)
          let actual := encode (actuallyFiltered index)
          IO.println s!"CAT_VALUE track={track} rank={rank} axis={axis.val} other={other} counts={raw} index={coordinates index} source={source} zero={zero} nested={nested} filtered={actual}"
        let leading := blocks.take 1
        let middle := (blocks.drop 1).take 2
        let trailing := (blocks.drop 1).drop 2
        let full := leading ++ (middle ++ trailing)
        let middleCount := total middle
        for variant in [0, 1, 2] do
          let start := if variant = 0 then 0 else if variant = 1 then min 1 middleCount else middleCount
          let length := middleCount - start
          have fits : start + length ≤ middleCount := by
            dsimp [start, length]
            split <;> (try split) <;> omega
          let source := frame.slice (concatenate full) (total leading + start) length
            (by rw [total_append, total_append]; omega)
          let target := frame.slice (concatenate middle) start length fits
          for index in OrderedCoordinates.enumerate (frame.shape length) do
            let lhs := encode (source index)
            let rhs := encode (target index)
            IO.println s!"CAT_SLICE track={track} rank={rank} axis={axis.val} other={other} counts={raw} variant={variant} start={start} length={length} index={coordinates index} source={lhs} target={rhs}"

#eval show IO Unit from do
  for rank in [1, 2, 3] do
    concatControls "integer" id id rank
    concatControls "word8" (BitVec.ofInt 8) (fun value : BitVec 8 => Int.ofNat value.toNat) rank
  for bits in [0, 0x80000000, 0x7fc01234, 0x7f801234, 0x7f800000, 0xff800000] do
    let value : Binary32 := ExecFloat.Binary.ofNatBits bits
    let block : Block lineFrame Binary32 := ⟨1, Tensor.constant value⟩
    let result := concatenate [block, block] (lineIndex (1 : Fin 2))
    IO.println s!"CAT_FLOAT input={bits} output={ExecFloat.Binary.toNatBits result}"
