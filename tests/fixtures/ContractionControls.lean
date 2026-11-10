import TensorRewrite

set_option autoImplicit false

open TensorRewrite.Pilot
open TensorRewrite.Pilot.Contraction

namespace ContractionControls

/-- Empty axis group. -/
def scalar : Shape 0 := Fin.elim0

/-- One axis of the given extent. -/
def vector (extent : Nat) : Shape 1 := fun _ => extent

/-- Two axes in dim0-major order. -/
def matrix (rows columns : Nat) : Shape 2 := fun axis => if axis.val = 0 then rows else columns

/-- Swap the two original operand axes. -/
def swap : AxisPermutation 2 where
  outputToInput := Fin.rev
  inputToOutput := Fin.rev
  output_input := by decide
  input_output := by decide

/-- Canonical batch/left/left axes occupy original positions 2/0/1. -/
def rotate : AxisPermutation 3 where
  outputToInput := fun axis => ⟨(axis.val + 2) % 3, by omega⟩
  inputToOutput := fun axis => ⟨(axis.val + 1) % 3, by omega⟩
  output_input := by decide
  input_output := by decide

/-- Source s8/s32 storage, result-s32 conversion, then signed evaluator promotion. -/
def promote (width : Nat) (value : Int) : BitVec 64 :=
  BitVec.ofInt 64 (BitVec.ofInt 32 (BitVec.ofInt width value).toInt).toInt

/-- Explicit per-input casts with the source's 64-bit intermediate product. -/
def multiply (leftWidth rightWidth : Nat) (lhs rhs : Int) : BitVec 64 :=
  promote leftWidth lhs * promote rightWidth rhs

/-- Narrow the accumulator to the signed s32 result. -/
def finish (value : BitVec 64) : Int := (BitVec.ofInt 32 value.toInt).toInt

/-- The replacement multiplies directly in the result word width. -/
def replacementProduct (leftWidth rightWidth : Nat) (lhs rhs : Int) : Int :=
  let left := BitVec.ofInt 32 (BitVec.ofInt leftWidth lhs).toInt
  let right := BitVec.ofInt 32 (BitVec.ofInt rightWidth rhs).toInt
  (left * right).toInt

/-- Nonuniform row-major operand labels test every coordinate permutation. -/
def label {rank : Nat} {shape : Shape rank} (index : Index shape) : Int :=
  Int.ofNat (LinearIndex.linearize shape index).val + 1

/-- Enumerate every result cell from the actual logical shape. -/
def observe {rank : Nat} {shape : Shape rank} (tensor : Tensor shape Int) : List Int :=
  (List.finRange (LinearIndex.elementCount shape)).map fun position =>
    tensor (LinearIndex.delinearize shape position)

/-- A paired before/after check; outputs the computed original only after equality holds. -/
def check {batch left right contracting : Nat} (name : String)
    (plan : Plan batch left right contracting) (leftWidth rightWidth : Nat)
    (lhs : Tensor plan.lhsShape Int) (rhs : Tensor plan.rhsShape Int)
    (after : Tensor plan.outputShape Int) : IO Unit := do
  let before := observe (dotTensor plan (· + ·) 0 (multiply leftWidth rightWidth) finish lhs rhs)
  if before != observe after then throw (IO.userError ("contraction mismatch: " ++ name))
  let values := if before.isEmpty then "empty" else String.intercalate "," (before.map toString)
  IO.println ("CONTRACTION_MODEL case=" ++ name ++ " values=" ++ values)

/-- Axis groups for native outer. -/
def outer : Plan 0 1 1 0 where
  batchShape := scalar
  leftShape := vector 2
  rightShape := vector 3
  contractShape := scalar
  leftOrder := AxisPermutation.identity 1
  rightOrder := AxisPermutation.identity 1

/-- Axis groups for native batchLeft. -/
def batchLeft : Plan 1 1 1 0 where
  batchShape := vector 2
  leftShape := vector 3
  rightShape := vector 4
  contractShape := scalar
  leftOrder := swap
  rightOrder := AxisPermutation.identity 2

/-- Axis groups for native batchRight. -/
def batchRight : Plan 1 1 1 0 where
  batchShape := vector 2
  leftShape := vector 3
  rightShape := vector 4
  contractShape := scalar
  leftOrder := AxisPermutation.identity 2
  rightOrder := swap

/-- Axis groups for native rankFour. -/
def rankFour : Plan 1 2 1 0 where
  batchShape := vector 2
  leftShape := matrix 2 3
  rightShape := vector 2
  contractShape := scalar
  leftOrder := rotate
  rightOrder := swap

/-- Axis groups for native contractEmpty. -/
def contractEmpty : Plan 0 1 1 1 where
  batchShape := scalar
  leftShape := vector 2
  rightShape := vector 3
  contractShape := vector 0
  leftOrder := AxisPermutation.identity 2
  rightOrder := swap

/-- Axis groups for native lhsFreeEmpty. -/
def lhsFreeEmpty : Plan 0 1 1 1 where
  batchShape := scalar
  leftShape := vector 0
  rightShape := vector 3
  contractShape := vector 2
  leftOrder := AxisPermutation.identity 2
  rightOrder := swap

/-- Axis groups for native rhsFreeEmpty. -/
def rhsFreeEmpty : Plan 0 1 1 1 where
  batchShape := scalar
  leftShape := vector 2
  rightShape := vector 0
  contractShape := vector 3
  leftOrder := AxisPermutation.identity 2
  rightOrder := swap

/-- Axis groups for native scalarOuter. -/
def scalarOuter : Plan 0 0 1 0 where
  batchShape := scalar
  leftShape := scalar
  rightShape := vector 2
  contractShape := scalar
  leftOrder := AxisPermutation.identity 0
  rightOrder := AxisPermutation.identity 1

/-- Axis groups for native outerFreeEmpty. -/
def outerFreeEmpty : Plan 0 1 1 0 where
  batchShape := scalar
  leftShape := vector 0
  rightShape := vector 3
  contractShape := scalar
  leftOrder := AxisPermutation.identity 1
  rightOrder := AxisPermutation.identity 1

/-- Axis groups for native matrixContract. -/
def matrixContract : Plan 0 1 1 1 where
  batchShape := scalar
  leftShape := vector 2
  rightShape := vector 4
  contractShape := vector 3
  leftOrder := AxisPermutation.identity 2
  rightOrder := swap

/-- The native outer vectors retain negative signed operands. -/
def outerLeft : Tensor outer.lhsShape Int := fun index => if (index 0).val = 0 then 2 else -3

def outerRight : Tensor outer.rhsShape Int := fun index =>
  match (index 0).val with | 0 => 5 | 1 => 7 | _ => -2

#eval do
  check "outer00" outer 32 32 outerLeft outerRight
    (outerTensor outer (replacementProduct 32 32) id outerLeft outerRight)
  check "outer01" outer 32 8 outerLeft outerRight
    (outerTensor outer (replacementProduct 32 8) id outerLeft outerRight)
  check "outer10" outer 8 32 outerLeft outerRight
    (outerTensor outer (replacementProduct 8 32) id outerLeft outerRight)
  check "outer11" outer 8 8 outerLeft outerRight
    (outerTensor outer (replacementProduct 8 8) id outerLeft outerRight)
  check "batch_left" batchLeft 32 32 label label
    (outerTensor batchLeft (replacementProduct 32 32) id label label)
  check "batch_right" batchRight 32 32 label label
    (outerTensor batchRight (replacementProduct 32 32) id label label)
  check "rank4" rankFour 32 32 label label
    (outerTensor rankFour (replacementProduct 32 32) id label label)
  check "matrix_contract" matrixContract 32 32 label label
    (dotTensor matrixContract (· + ·) 0 (multiply 32 32) finish label label)
  check "contract_empty" contractEmpty 32 32 label label
    (Tensor.constant 0)
  check "lhs_free_empty" lhsFreeEmpty 32 32 label label
    (Tensor.constant 0)
  check "rhs_free_empty" rhsFreeEmpty 32 32 label label
    (Tensor.constant 0)
  check "scalar_outer" scalarOuter 32 32 (fun _ => 2)
    (fun index => if (index 0).val = 0 then 5 else -3)
    (outerTensor scalarOuter (replacementProduct 32 32) id (fun _ => 2)
      (fun index => if (index 0).val = 0 then 5 else -3))
  check "outer_free_empty" outerFreeEmpty 32 32 label label (Tensor.constant 0)
  check "option_off" outer 32 32 outerLeft outerRight
    (dotTensor outer (· + ·) 0 (multiply 32 32) finish outerLeft outerRight)
  check "layout_on" outer 32 32 outerLeft outerRight
    (dotTensor outer (· + ·) 0 (multiply 32 32) finish outerLeft outerRight)

-- The witness uses only the minimal one-MAC bit profile, not a complete IEEE model.
#eval IO.println ("ZERO_MAC_MODEL original=" ++ toString ZeroMacProfile.positiveZero.toNat ++
  " replacement=" ++ toString ZeroMacProfile.negativeZero.toNat)

end ContractionControls
