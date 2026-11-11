module

public import TensorRewrite.Theory.WindowTupleFamilyProof
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! Singleton-tuple removal for the library's actual binary32 addition and stored bits. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.WindowTupleFloat

open Pilot FloatLib.Floats

/-- The actual binary32 scalar fold is unchanged by pure singleton-tuple unpacking. -/
theorem binary32_tuple {rank : Nat} (plan : ReductionWindow.Plan rank)
    (initial padding : Fin 1 → Binary32) (inputs : Fin 1 → Tensor plan.inputShape Binary32) :
    WindowTupleFamily.source .singleton plan (fun first second _ =>
      ExecFloat.add (first 0) (second 0)) initial padding inputs =
      fun _ => ReductionWindow.reduce plan ExecFloat.add (initial 0) (padding 0) (inputs 0) :=
  WindowTupleFamily.rewrite_sound .singleton plan _ initial padding inputs

/-- Stored binary32 encodings agree, including exceptional values; flags/schedules stay outside. -/
theorem binary32_tuple_bits {rank : Nat} (plan : ReductionWindow.Plan rank)
    (initial padding : Fin 1 → Binary32) (inputs : Fin 1 → Tensor plan.inputShape Binary32) :
    (fun component => Tensor.map ExecFloat.Binary.toNatBits
      (WindowTupleFamily.source .singleton plan (fun first second _ =>
        ExecFloat.add (first 0) (second 0)) initial padding inputs component)) =
      fun _ => Tensor.map ExecFloat.Binary.toNatBits
        (ReductionWindow.reduce plan ExecFloat.add (initial 0) (padding 0) (inputs 0)) := by
  rw [binary32_tuple]

end TensorRewrite.Theory.WindowTupleFloat
