module

public import TensorRewrite.Libraries.FloatingPoint
public import FloatLib.Floats.Formats.BinaryInterchange.Configured.Value.Core

/-! A fixed-order uniform binary32 sum need not equal value times the converted count. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.UniformSum

open FloatLib.Floats

local notation "b32(" value ")" => (ExecFloat.Binary.ofNatBits value : Binary32)

/-- Ten rounded binary32 additions of the encoding nearest one tenth differ from multiplication.
This is a fixed-order stored-bit contract refutation, not a collective schedule/refinement claim. -/
theorem binary32_uniform_product_refuted :
    ExecFloat.Binary.toNatBits
      ((List.replicate 10 b32(0x3dcccccd)).foldl ExecFloat.add b32(0)) = 0x3f800001 ∧
    ExecFloat.Binary.toNatBits (ExecFloat.mul b32(0x3dcccccd) b32(0x41200000)) = 0x3f800000 := by
  decide

end TensorRewrite.Theory.UniformSum
