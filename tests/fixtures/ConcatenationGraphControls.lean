import TensorRewrite.Theory.ConcatenationGraphCounterexamples
import TensorRewrite.Theory.OrderedCoordinates
import TensorRewrite.Libraries.FloatingPoint
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.Theory.Concatenation FloatLib.Floats

private def csv (values : List Nat) : String :=
  if values.isEmpty then "-" else String.intercalate "," (values.map toString)

private def coords {rank : Nat} {shape : Shape rank} (index : Index shape) : String :=
  csv ((List.finRange rank).map fun axis => (index axis).val)

private def shapeCSV {rank : Nat} (shape : Shape rank) : String :=
  csv ((List.finRange rank).map shape)

private def datum {rank : Nat} {shape : Shape rank} (index : Index shape) : Int :=
  Int.ofNat ((List.finRange rank).foldl
    (fun value axis => value + (axis.val + 1) * 10 * (index axis).val) 0) - 17

private def adjacentControls {α : Type} (track : String) (convert : Int → α)
    (encode : α → Int) (rank : Nat) : IO Unit := do
  for axis in List.finRange rank do
    for other in [0, 1, 2] do
      let otherExtent : Nat := if other = 0 then 0 else 5
      let rawOther : SliceShape.Axis :=
        if other = 0 then ⟨0, 0, 1⟩ else if other = 1 then ⟨0, 5, 1⟩ else ⟨1, 4, 2⟩
      have otherValid : SliceShape.IsWellFormed otherExtent rawOther.elementCount.toNat rawOther := by
        apply axis_valid_inferred <;> by_cases zero : other = 0 <;>
          by_cases one : other = 1 <;> simp [rawOther, otherExtent, zero, one]
      let frame : Frame rank := ⟨fun _ => otherExtent, axis⟩
      let crop : Crop frame := ⟨fun _ => rawOther.elementCount.toNat, fun _ => rawOther,
        fun _ _ => otherValid⟩
      for config in ([(0, 0, 0, 0, 1), (5, 0, 2, 5, 1), (5, 1, 2, 5, 2),
          (5, 0, 3, 5, 2), (5, 1, 1, 5, 3), (5, 2, 5, 5, 1), (5, 0, 0, 4, 2)] : List (Nat × Nat × Nat × Nat × Nat)) do
        let (extent, start, middle, stop, stride) := config
        let first : SliceShape.Axis := ⟨start, middle, stride⟩
        let firstLength := first.elementCount.toNat
        let next := start + firstLength * stride
        let second : SliceShape.Axis := ⟨next, stop, stride⟩
        let secondLength := second.elementCount.toNat
        if validFirst : SliceShape.IsWellFormed extent firstLength first then
          if validSecond : SliceShape.IsWellFormed extent secondLength second then
            have adjacent : second.start = first.start + (firstLength : Int) * first.stride := by
              simp [second, next, first]
            let input : Tensor (frame.shape extent) α := fun index => convert (datum index)
            let firstBlock := crop.blockWith input first firstLength validFirst
            let secondBlock := crop.blockWith input second secondLength validSecond
            let merged := crop.blockWith input (mergeAxis first second) (firstLength + secondLength)
              (merged_axis_valid first second validFirst validSecond rfl adjacent)
            let sourceBlocks := [constantBlock 1 (convert 71), firstBlock, secondBlock,
              constantBlock 2 (convert 93)]
            let targetBlocks := [constantBlock 1 (convert 71), merged, constantBlock 2 (convert 93)]
            have same : total targetBlocks = total sourceBlocks := by
              simp [targetBlocks, sourceBlocks, total, constantBlock, firstBlock, secondBlock,
                merged, Crop.blockWith]
              omega
            let target := crop.outputFrame.castTensor same (concatenate targetBlocks)
            let key := s!"track={track} rank={rank} axis={axis.val} other={other} raw={extent},{start},{middle},{stop},{stride}"
            IO.println s!"AG_PROFILE {key} counts={firstLength},{secondLength} shape={shapeCSV (crop.outputFrame.shape (total sourceBlocks))}"
            for index in OrderedCoordinates.enumerate (crop.outputFrame.shape (total sourceBlocks)) do
              IO.println s!"AG_VALUE {key} index={coords index} source={encode (concatenate sourceBlocks index)} target={encode (target index)}"

private def padControls {α : Type} (track : String) (convert : Int → α)
    (encode : α → Int) (rank : Nat) : IO Unit := do
  for axis in List.finRange rank do
    for other in [0, 1, 2] do
      let frame : Frame rank := ⟨fun _ => other, axis⟩
      for extent in [0, 1, 3] do
        let input : Tensor (frame.shape extent) α := fun index => convert (datum index)
        for width in [0, 1, 2] do
          for highSide in [false, true] do
            let low := if highSide then 0 else width
            let high := if highSide then width else 0
            let blocks := if highSide then
              [(⟨extent, input⟩ : Block frame α), constantBlock width (convert 71)] else
              [constantBlock width (convert 71), (⟨extent, input⟩ : Block frame α)]
            have same : total blocks = low + extent + high := by
              dsimp [blocks, low, high]
              cases highSide <;> simp [total, constantBlock, Nat.add_comm]
            let source := frame.castTensor same (concatenate blocks)
            let target := ShapeTransport.tensorAlong (edgePadding_shape frame low high)
              ((frame.edgePadding low high).tensor (convert 71) input)
            let key := s!"track={track} rank={rank} axis={axis.val} other={other} extent={extent} low={low} high={high}"
            IO.println s!"PG_PROFILE {key} shape={shapeCSV (frame.shape (low + extent + high))}"
            for index in OrderedCoordinates.enumerate (frame.shape (low + extent + high)) do
              IO.println s!"PG_VALUE {key} index={coords index} source={encode (source index)} target={encode (target index)}"

private def repeatControls {α : Type} (track : String) (convert : Int → α)
    (encode : α → Int) (tailRank : Nat) : IO Unit := do
  let rank := tailRank + 1
  for axis in List.finRange rank do
    for other in [0, 1, 3] do
      let frame : Frame rank := ⟨fun _ => other, axis⟩
      let input : Tensor (frame.shape 1) α := fun index => convert (datum index)
      for copies in [0, 1, 2, 4] do
        let plan := UnitAxis.ofAxis frame.extents axis
        let source := frame.castTensor (total_replicate_unit input copies)
          (concatenate (List.replicate copies (⟨1, input⟩ : Block frame α)))
        let target := repeatTarget frame copies input
        let axes := csv ((List.finRange tailRank).map fun axis =>
          (plan.broadcastAxes.values[axis]).toNat)
        let key := s!"track={track} rank={rank} axis={axis.val} other={other} copies={copies}"
        IO.println s!"RG_PROFILE {key} dropped={shapeCSV plan.outputShape} axes={axes} shape={shapeCSV (frame.shape copies)}"
        for index in OrderedCoordinates.enumerate (frame.shape copies) do
          IO.println s!"RG_VALUE {key} index={coords index} source={encode (source index)} target={encode (target index)}"

#eval show IO Unit from do
  for rank in [1, 2, 3] do
    adjacentControls "integer" id id rank
    adjacentControls "word8" (BitVec.ofInt 8) (fun value : BitVec 8 => Int.ofNat value.toNat) rank
    padControls "integer" id id rank
    padControls "word8" (BitVec.ofInt 8) (fun value : BitVec 8 => Int.ofNat value.toNat) rank
  for tailRank in [0, 1, 2] do
    repeatControls "integer" id id tailRank
    repeatControls "word8" (BitVec.ofInt 8) (fun value : BitVec 8 => Int.ofNat value.toNat) tailRank
  for bits in [0, 0x80000000, 0x7fc01234, 0x7f801234, 0x7f800000, 0xff800000] do
    let value : Binary32 := ExecFloat.Binary.ofNatBits bits
    let input : Tensor (lineFrame.shape 1) Binary32 := Tensor.constant value
    let repeatedValue := repeatTarget lineFrame 2 input (lineIndex (1 : Fin 2))
    let pad := ShapeTransport.tensorAlong (edgePadding_shape (extent := 1) lineFrame 1 0)
      ((lineFrame.edgePadding 1 0).tensor value input) (lineIndex (0 : Fin 2))
    IO.println s!"CG_FLOAT input={bits} repeat={ExecFloat.Binary.toNatBits repeatedValue} pad={ExecFloat.Binary.toNatBits pad}"
