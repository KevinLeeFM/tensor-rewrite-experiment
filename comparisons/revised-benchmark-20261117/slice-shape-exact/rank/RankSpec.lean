module
public import TensorRewrite.Pilot.Indexing
public import TensorRewrite.Pilot.IndexMaps
public import SliceShapeExactSpec

@[expose] public section
set_option autoImplicit false
namespace TensorRewrite.Pilot.SliceShape.RankExact

/-- Legal rank-wide static slice at its supplied output shape. -/
abbrev Legal {r : Nat} (s t : Shape r) (a : Fin r → Axis) :=
  ∀ k, IsWellFormed (s k) (t k) (a k)

/-- Signed axis lookups pulled back along the existing bounded logical map. -/
def sliced {r : Nat} {s t : Shape r} {α : Type} (a : Fin r → Axis)
    (v : Legal s t a) (x : Tensor s α) : Tensor t α :=
  Tensor.reindex (IndexMaps.sliceIndex a v) x

/-- Source update only on axes contained in the supplied reverse mask. -/
def reordered {r : Nat} (s : Shape r) (a : Fin r → Axis) (mask : Fin r → Bool) :=
  fun k => if mask k then reorderReverse (s k) (a k) else a k

/-- Exact rank-wide legality and arbitrary logical tensor value equality after stride removal. -/
def StrideGoal : Prop :=
  ∀ {r : Nat} (s t : Shape r) (a : Fin r → Axis) (v : Legal s t a),
  (Legal s t (fun k => removeRedundantStride (a k)) ↔
    ∀ k, (a k).stride = 1 ∨ (a k).start < (a k).limit) ∧
  ∀ (w : Legal s t (fun k => removeRedundantStride (a k))) (α : Type) (x : Tensor s α),
    sliced a v x = sliced _ w x

/-- Exact rank-wide legality and arbitrary logical tensor value equality when commuting reverse. -/
def ReverseGoal : Prop :=
  ∀ {r : Nat} (s t : Shape r) (a : Fin r → Axis) (v : Legal s t a) (mask : Fin r → Bool),
  (Legal s t (reordered s a mask) ↔
    ∀ k, mask k = true → (a k).stride = 1 ∨ (a k).start < (a k).limit) ∧
  ∀ (w : Legal s t (reordered s a mask)) (α : Type) (x : Tensor s α),
    sliced a v (Tensor.reverse mask x) = Tensor.reverse mask (sliced _ w x)
end TensorRewrite.Pilot.SliceShape.RankExact
