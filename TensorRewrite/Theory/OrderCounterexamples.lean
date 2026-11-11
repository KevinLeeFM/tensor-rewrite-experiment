module

public import TensorRewrite.Theory.OrderInstances
public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Instances

/-! Bounds, signedness and actual binary32 comparison observations prevent unjustified order
reuse. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderFamily

open Pilot FloatLib.Floats

/-- Max/Min to Clamp requires ordered bounds; reversed bounds produce two versus one. -/
theorem reversed_bounds_refuted :
    max (2 : Int) (min 0 1) ≠ min (max (0 : Int) 2) 1 := by decide

/-- The same stored byte has different Max results under signed and unsigned interpretation. -/
theorem signedness_refuted :
    (max (⟨0#8⟩ : Word false 8) ⟨255#8⟩).bits ≠
      (max (⟨0#8⟩ : Word true 8) ⟨255#8⟩).bits := by decide

/-- Actual numerical Eq/Le/Ge all return false for a binary32 quiet NaN compared to itself. -/
theorem binary32_nan_self_refuted :
    let nan : Binary32 := ExecFloat.Binary.ofNatBits 0x7fc00000
    ExecFloat.compareEqual nan nan = false ∧ ExecFloat.compareLessEqual nan nan = false ∧
      ExecFloat.compareGreaterEqual nan nan = false := by decide

/-- Binary32 numerical equality identifies signed zeros although their stored words differ. -/
theorem binary32_zero_observation_refuted :
    let positive : Binary32 := ExecFloat.Binary.ofNatBits 0
    let negative : Binary32 := ExecFloat.Binary.ofNatBits 0x80000000
    ExecFloat.compareEqual positive negative = true ∧ positive ≠ negative := by decide

end TensorRewrite.Theory.OrderFamily
