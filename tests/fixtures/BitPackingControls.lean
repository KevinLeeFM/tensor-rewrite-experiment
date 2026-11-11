import TensorRewrite.Theory.BitPackingCounterexamples
import TensorRewrite.Theory.BitPackingCell
import TensorRewrite.Theory.OrderedCoordinates
import TensorRewrite.Libraries.FloatingPoint
import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

open TensorRewrite.Pilot TensorRewrite.Theory TensorRewrite.Theory.BitPacking FloatLib.Floats

private def csv (values : List Nat) : String :=
  if values.isEmpty then "-" else String.intercalate "," (values.map toString)

private def orderName : Order → String
  | .leastFirst => "lsb"
  | .mostFirst => "msb"

private def orders : List Order := [.leastFirst, .mostFirst]

private def coords {rank : Nat} {shape : Shape rank} (index : Index shape) : String :=
  csv ((List.finRange rank).map fun axis => (index axis).val)

private def shapeCSV {rank : Nat} (shape : Shape rank) : String :=
  csv ((List.finRange rank).map shape)

private def datum {rank : Nat} {shape : Shape rank} (index : Index shape) : Nat :=
  (List.finRange rank).foldl (fun value axis => value + (axis.val + 1) * 37 * (index axis).val) 4660

private def bufferControls : IO Unit := do
  for cells in [0, 1, 2, 3, 4] do
    for width in [0, 1, 3, 4, 8, 16, 32] do
      for outputWidth in [0, 1, 3, 4, 8, 16, 32] do
        let sizes := if outputWidth = 0 then [0, 2] else [cells * width / outputWidth]
        for outputCells in sizes do
          if same : cells * width = outputCells * outputWidth then
            for inputOrder in orders do
              for outputOrder in orders do
                for seed in [0, 1] do
                  let input : Words cells width := fun cell =>
                    BitVec.ofNat width (305419896 + 37 * cell.val + 113 * seed)
                  let direct := repack inputOrder outputOrder same input
                  let throughBits := repack inputOrder .mostFirst
                    (show cells * width = (cells * width) * 1 by omega) input
                  let through := repack .mostFirst outputOrder
                    (show (cells * width) * 1 = outputCells * outputWidth by omega) throughBits
                  let back := repack outputOrder inputOrder same.symm direct
                  let original := csv ((List.finRange cells).map fun cell => (input cell).toNat)
                  let result := csv ((List.finRange outputCells).map fun cell => (direct cell).toNat)
                  let nested := csv ((List.finRange outputCells).map fun cell => (through cell).toNat)
                  let inverse := csv ((List.finRange cells).map fun cell => (back cell).toNat)
                  IO.println s!"BP_BUFFER cells={cells} width={width} out_cells={outputCells} out_width={outputWidth} in_order={orderName inputOrder} out_order={orderName outputOrder} seed={seed} input={original} direct={result} through={nested} back={inverse}"

private def shapeControls (rank : Nat) : IO Unit := do
  for other in [0, 1, 2] do
    let shape : Shape rank := fun _ => other
    for factor in [0, 1, 2, 4] do
      for width in [1, 3, 8, 16] do
        for order in orders do
          let input : Tensor shape (BitVec (factor * width)) := fun index =>
            BitVec.ofNat (factor * width) (datum index)
          let parts := splitLast factor order input
          let back := joinLast shape factor order parts
          let expanded : Tensor (appendAxis shape factor) (BitVec width) :=
            fun index => BitVec.ofNat width (datum index + 113)
          let expandedBack := splitLast factor order (joinLast shape factor order expanded)
          let key := s!"rank={rank} other={other} factor={factor} width={width} order={orderName order}"
          IO.println s!"BP_SHAPE {key} input_shape={shapeCSV shape} output_shape={shapeCSV (appendAxis shape factor)}"
          for index in OrderedCoordinates.enumerate shape do
            IO.println s!"BP_ORIGINAL {key} index={coords index} source={(input index).toNat} back={(back index).toNat}"
          for index in OrderedCoordinates.enumerate (appendAxis shape factor) do
            IO.println s!"BP_PART {key} index={coords index} split={(parts index).toNat} arbitrary={(expanded index).toNat} back={(expandedBack index).toNat}"

private def matrixShape : Shape 2 := fun _ => 2
private def middleShape : Shape 3 := fun _ => 2
private def outputShape : Shape 2 := fun axis => if axis = 0 then 2 else 4

private def chooseLayout (rank : Nat) (column : Bool) : DenseLayout rank :=
  if column then DenseLayout.columnMajor rank else DenseLayout.rowMajor rank

private def layoutControls : IO Unit := do
  for inputColumn in [false, true] do
    for middleColumn in [false, true] do
      for outputColumn in [false, true] do
        let inputLayout := chooseLayout 2 inputColumn
        let middleLayout := chooseLayout 3 middleColumn
        let outputLayout := chooseLayout 2 outputColumn
        have left : LinearIndex.elementCount (inputLayout.orderedShape matrixShape) * 16 =
            LinearIndex.elementCount (middleLayout.orderedShape middleShape) * 8 := by
          cases inputColumn <;> cases middleColumn <;> decide
        have right : LinearIndex.elementCount (middleLayout.orderedShape middleShape) * 8 =
            LinearIndex.elementCount (outputLayout.orderedShape outputShape) * 8 := by
          cases middleColumn <;> cases outputColumn <;> decide
        for inputOrder in orders do
          for middleOrder in orders do
            for outputOrder in orders do
              let input : Tensor matrixShape (BitVec 16) := fun index =>
                BitVec.ofNat 16 (datum index)
              let intermediate := physicalConvert inputLayout middleLayout middleShape
                inputOrder middleOrder left input
              let through := physicalConvert middleLayout outputLayout outputShape
                middleOrder outputOrder right intermediate
              let direct := physicalConvert inputLayout outputLayout outputShape
                inputOrder outputOrder (left.trans right) input
              let key := s!"in_col={inputColumn} mid_col={middleColumn} out_col={outputColumn} in_order={orderName inputOrder} mid_order={orderName middleOrder} out_order={orderName outputOrder}"
              IO.println s!"BP_LAYOUT {key} input_shape=2,2 middle_shape=2,2,2 output_shape=2,4"
              for index in OrderedCoordinates.enumerate outputShape do
                IO.println s!"BP_LAYOUT_VALUE {key} index={coords index} direct={(direct index).toNat} through={(through index).toNat}"
        let midSame := chooseLayout 2 middleColumn
        let outSame := chooseLayout 2 outputColumn
        have sameLeft : LinearIndex.elementCount (inputLayout.orderedShape matrixShape) =
            LinearIndex.elementCount (midSame.orderedShape matrixShape) := by
          cases inputColumn <;> cases middleColumn <;> decide
        have sameRight : LinearIndex.elementCount (midSame.orderedShape matrixShape) =
            LinearIndex.elementCount (outSame.orderedShape matrixShape) := by
          cases middleColumn <;> cases outputColumn <;> decide
        let input : Tensor matrixShape (BitVec 16) := fun index => BitVec.ofNat 16 (datum index)
        let function : BitVec 16 → BitVec 16 := fun value => ~~~value
        let source := DenseLayout.bitcastTensor midSame outSame matrixShape sameRight
          (Tensor.map function
            (DenseLayout.bitcastTensor inputLayout midSame matrixShape sameLeft input))
        let target := DenseLayout.bitcastTensor inputLayout outSame matrixShape
          (sameLeft.trans sameRight) (Tensor.map function input)
        for index in OrderedCoordinates.enumerate matrixShape do
          IO.println s!"BP_CELL in_col={inputColumn} mid_col={middleColumn} out_col={outputColumn} index={coords index} source={(source index).toNat} target={(target index).toNat}"

#eval show IO Unit from do
  bufferControls
  for rank in [0, 1, 2, 3] do shapeControls rank
  layoutControls
  for bits in [0, 0x80000000, 0x3f800000, 0x7fc01234, 0x7f801234, 0x7f800000, 0xff800000] do
    let value : Binary32 := ExecFloat.Binary.ofNatBits bits
    let input : Words 1 32 := fun _ => BitVec.ofNat 32 (ExecFloat.Binary.toNatBits value)
    let bytes := repack (outputCells := 4) (outputWidth := 8) .leastFirst .leastFirst (by decide) input
    let back := repack (outputCells := 1) (outputWidth := 32) .leastFirst .leastFirst (by decide) bytes
    let observed : Binary32 := ExecFloat.Binary.ofNatBits (back 0).toNat
    let raw := csv ((List.finRange 4).map fun cell => (bytes cell).toNat)
    IO.println s!"BP_FLOAT input={bits} bytes={raw} back={ExecFloat.Binary.toNatBits observed}"
