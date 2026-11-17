module
public import TensorRewrite.Pilot.IndexMapLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.StaticIdentity
open TensorRewrite.Pilot
/-- Forward a shape-compatible static Slice for every legal set of attributes. -/
def Goal : Prop :=
  ∀ {r : Nat} (s : Shape r) (a : Fin r → SliceShape.Axis)
    (v : ∀ k, SliceShape.IsWellFormed (s k) (s k) (a k))
    (α : Type) (x : Tensor s α), (fun j => x (IndexMaps.sliceIndex a v j)) = x
end RevisedBenchmark.StaticIdentity
