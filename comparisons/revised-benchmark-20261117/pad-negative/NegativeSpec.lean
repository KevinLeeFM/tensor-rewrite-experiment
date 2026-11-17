module
public import SignedPadHistorical
public import TensorRewrite.Pilot.IndexMapLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.NegativePad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

/-- Size from padding with the negative edges set to zero. -/
def middle {r : Nat} {s o : Shape r} (p : Params s o) : Shape r :=
  fun d => (extent (s d) (max 0 (p.low d)) (max 0 (p.high d)) (p.interior d)).toNat

/-- The source forms a unit-stride crop with the removed low and high edges. -/
def crop {r : Nat} {s o : Shape r} (p : Params s o) (d : Fin r) : SliceShape.Axis :=
  ⟨max 0 (-p.low d), (middle p d : Int) + min 0 (p.high d), 1⟩

/-- Construct the actual intermediate Pad with exact attributes and legal crop.
    Their composed tensor is the original signed Pad for every input and fill. -/
def Goal : Prop :=
  ∀ {r : Nat} {s o : Shape r} (p : Params s o),
    ∃ mid : Params s (middle p),
      mid.low = (fun d => max 0 (p.low d)) ∧
      mid.high = (fun d => max 0 (p.high d)) ∧ mid.interior = p.interior ∧
      ∃ valid : ∀ d, SliceShape.IsWellFormed (middle p d) (o d) (crop p d),
        ∀ {α : Type} (fill : α) (xs : Tensor s α),
          tensor p fill xs = fun j => tensor mid fill xs (IndexMaps.sliceIndex (crop p) valid j)
end RevisedBenchmark.NegativePad
