module

public import TensorRewrite.Theory.DynamicUpdateStatic
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! Decoding, nested clamping and stored-zero observations are separate mathematical partitions. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.DynamicUpdate

open Pilot FloatLib.Floats

/-- One-axis windows used only to state concrete diagnostic witnesses. -/
def diagnosticLineWindow (extent width : Nat) (fits : width ≤ extent) (start : Int) :
    Window (fun _ : Fin 1 => extent) (fun _ : Fin 1 => width) where
  starts _ := start
  fits _ := fits

/-- Signed and unsigned decoding of the same byte can choose different clamped slice positions. -/
theorem decoded_signedness_refuted :
    let signed := diagnosticLineWindow 3 1 (by decide) (255#8).toInt
    let unsigned := diagnosticLineWindow 3 1 (by decide) (Int.ofNat (255#8).toNat)
    let input : Tensor (fun _ : Fin 1 => 3) Nat := fun i => (i 0).val
    let index : Index (fun _ : Fin 1 => 1) := fun _ => 0
    signed.slice input index ≠ unsigned.slice input index := by decide

/-- Adding raw starts loses independently clipped offsets: the correct read is two, not four. -/
theorem raw_nested_sum_refuted :
    let first := diagnosticLineWindow 5 3 (by decide) (-2)
    let second := diagnosticLineWindow 3 1 (by decide) 100
    let naive := diagnosticLineWindow 5 1 (by decide) (-2 + 100)
    let input : Tensor (fun _ : Fin 1 => 5) Nat := fun i => (i 0).val
    let index : Index (fun _ : Fin 1 => 1) := fun _ => 0
    (first.compose second).slice input index ≠ naive.slice input index := by decide

/-- Moving binary32 Add inside a zero-based update changes retained negative-zero stored bits. -/
theorem binary32_add_update_refuted :
    let window := diagnosticLineWindow 2 1 (by decide) 1
    let zero : Binary32 := ExecFloat.Binary.ofNatBits 0
    let negativeZero : Binary32 := ExecFloat.Binary.ofNatBits 0x80000000
    let base : Tensor (fun _ : Fin 1 => 2) Binary32 := Tensor.constant negativeZero
    let update : Tensor (fun _ : Fin 1 => 1) Binary32 := Tensor.constant zero
    let left := Tensor.map₂ ExecFloat.add base (window.update (Tensor.constant zero) update)
    let right := window.update base (Tensor.map₂ ExecFloat.add (window.slice base) update)
    let index : Index (fun _ : Fin 1 => 2) := fun _ => 0
    ExecFloat.Binary.toNatBits (left index) ≠ ExecFloat.Binary.toNatBits (right index) := by decide

end TensorRewrite.Theory.DynamicUpdate
