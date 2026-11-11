import TensorRewrite.Theory.BitPackingCounterexamples

open TensorRewrite.Pilot TensorRewrite.Theory.BitPacking

example : repack (outputWidth := 16) .leastFirst .leastFirst (by decide) bytePair (0 : Fin 1) =
    repack (outputWidth := 16) .mostFirst .mostFirst (by decide) bytePair (0 : Fin 1) := by decide

example : repack (outputWidth := 16) .leastFirst .leastFirst (by decide) bytePair (0 : Fin 1) =
    (bytePair 0).zeroExtend 16 := by decide

example : physicalConvert (DenseLayout.rowMajor 2) (DenseLayout.columnMajor 2)
    (fun _ => 2) .leastFirst .leastFirst (by decide) matrixInput
    (fun axis => if axis = 0 then 0 else 1) =
  matrixInput (fun axis => if axis = 0 then 0 else 1) := by decide

example : (0 * 8 = 0 * 16) → (8 : Nat) = 16 := by decide
