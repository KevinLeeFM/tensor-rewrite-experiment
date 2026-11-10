module

public import TensorRewrite.Pilot.DynamicSliceTensor

/-! Evaluator-relative diagnostic on the concrete 10 → 6 → 2 shape chain.
Typed HLO clamps decode u64 as unsigned; DynamicSlice's observed conversion
decodes it as signed. These definitions do not adopt a backend contract. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.NestedUnsigned64

open DynamicIndex

/-- First selected coordinate of the original nested evaluator profile. -/
def originalStart (inner outer : BitVec 64) : Int :=
  clampStart 10 6 (evaluatorUnsigned64 inner) +
    clampStart 6 2 (evaluatorUnsigned64 outer)

/-- First coordinate after typed clamps, word addition and final evaluator decoding. -/
def rewrittenStart (inner outer : BitVec 64) : Int :=
  clampStart 10 2 (evaluatorUnsigned64 (BitVec.ofInt 64
    (combinedStart 10 6 2 (unsignedValue inner) (unsignedValue outer))))

end TensorRewrite.Pilot.NestedUnsigned64
