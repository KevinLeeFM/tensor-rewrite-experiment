module
public import TensorRewrite.Pilot.IndexMaps
public import TensorRewrite.Pilot.Reshape
public import TensorRewrite.Pilot.LinearIndexLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastOrdered
open TensorRewrite.Pilot
/-- All static typed strict embeddings, arbitrary rank and zero extents included. -/
def Target : Prop :=
  ∀ {m n : Nat} (s : Shape m) (t : Shape n)
    (axes : IndexMaps.BroadcastAxes m n)
    (_ : ∀ a b, a < b → axes.decode a < axes.decode b)
    (matched : ∀ a, s a = t (axes.decode a))
    (same : LinearIndex.elementCount s = LinearIndex.elementCount t)
    (α : Type) (x : Tensor s α),
    (fun j => x (IndexMaps.broadcastIndex axes matched j)) = Reshape.reshapeTensor x t same
end RevisedBenchmark.BroadcastOrdered
