module

public import TensorRewrite.Theory.OrderedScatterGraph
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! Reducer-role, duplicate-order, rounded translation and out-of-bounds policy certificates. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot FloatLib.Floats

/-- A scalar operand has one actual coordinate. -/
def scalarShape : Shape 0 := Fin.elim0

/-- The unique scalar coordinate is used for explicit repeated-address events. -/
def scalarIndex : Index scalarShape := fun axis => Fin.elim0 axis

/-- Two updates hit the same scalar, so reducer parameter mistakes accumulate twice. -/
def duplicateWordEvents : List (Entry scalarShape (BitVec 4)) :=
  [⟨some scalarIndex, 1#4⟩, ⟨some scalarIndex, 7#4⟩]

/-- An Add-shaped repeated-current reducer breaks base translation on the actual ordered trace. -/
theorem repeated_parameter_refuted :
    (Tensor.map₂ (· + ·) (Tensor.constant 3#4)
      (run (ReducerIndex.ScatterRoles.combine .current .current)
        (Tensor.constant 2#4) duplicateWordEvents) scalarIndex).toNat = 11 ∧
    (run (ReducerIndex.ScatterRoles.combine .current .current)
      (Tensor.constant (3#4 + 2#4)) duplicateWordEvents scalarIndex).toNat = 4 := by
  decide

/-- Reordering duplicate-address updates is observable for a valid pure nonassociative reducer. -/
theorem duplicate_order_refuted :
    run (fun a b : Nat => 10*a+b) (Tensor.constant 0)
      [⟨some scalarIndex, 1⟩, ⟨some scalarIndex, 2⟩] scalarIndex = 12 ∧
    run (fun a b : Nat => 10*a+b) (Tensor.constant 0)
      [⟨some scalarIndex, 2⟩, ⟨some scalarIndex, 1⟩] scalarIndex = 21 := by
  decide

local notation "b32(" value ")" => (ExecFloat.Binary.ofNatBits value : Binary32)

/-- Actual binary32 Scatter/Add base translation changes finite stored bits through rounding. -/
theorem binary32_translate_refuted :
    ExecFloat.Binary.toNatBits
      (ExecFloat.add b32(0xcb800000)
        (scatter (fullWindowPlan scalarShape) ExecFloat.add (Tensor.constant b32(0x4b800000))
          (fun _ => Fin.elim0) (fun _ => Tensor.constant b32(0x3f800000)) scalarIndex)) = 0 ∧
    ExecFloat.Binary.toNatBits
      (scatter (fullWindowPlan scalarShape) ExecFloat.add
        (Tensor.constant (ExecFloat.add b32(0xcb800000) b32(0x4b800000)))
        (fun _ => Fin.elim0) (fun _ => Tensor.constant b32(0x3f800000)) scalarIndex) =
          0x3f800000 := by
  decide

/-- A rank-one element-dropped profile used to distinguish raw index semantics from clipping. -/
def singlePointPlan : Plan 1 0 1 where
  operandShape := fun _ => 2
  batchShape := Fin.elim0
  windowShape := fun _ => 1
  indexAxes := ⟨#v[0], by decide⟩
  injective := fun first second _ => Subsingleton.elim first second

/-- A negative Scatter target is dropped; clamping it instead creates a different result. -/
theorem clamping_refuted :
    scatter singlePointPlan (· + ·) (Tensor.constant (2 : Nat)) (fun _ _ => -1)
      (fun _ => Tensor.constant 9) (fun _ => ⟨0, by decide +revert⟩) = 2 ∧
    run (shape := singlePointPlan.operandShape) (· + ·) (Tensor.constant (2 : Nat))
      [⟨some (fun _ => ⟨0, by decide +revert⟩), 9⟩] (fun _ => ⟨0, by decide +revert⟩) = 11 := by
  decide

end TensorRewrite.Theory.OrderedScatter
