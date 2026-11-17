module
public import TensorRewrite.Pilot.SliceShape
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceComposeStatic
open TensorRewrite.Pilot.SliceShape
/-- Combined unit-stride static slice attributes remain well formed. -/
def Goal : Prop :=
  ∀ (extent middle output : Int) (inner outer : Axis),
    IsWellFormed extent middle inner → IsWellFormed middle output outer →
    inner.stride = 1 → outer.stride = 1 →
    IsWellFormed extent output
      { start := inner.start + outer.start, limit := inner.start + outer.limit, stride := 1 }
#print Goal
end RevisedBenchmark.SliceComposeStatic
