module
public import SignedPadHistorical
public import TensorRewrite.Pilot.IndexMapLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SliceOfPad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad

def shifted {r : Nat} {s m : Shape r} (p : Params s m) (axes : Fin r → SliceShape.Axis)
    (d : Fin r) : SliceShape.Axis :=
  ⟨(axes d).start - p.low d, (axes d).limit - p.low d, (axes d).stride⟩

def Inside : Prop :=
  ∀ {r : Nat} {s m o : Shape r} (p : Params s m) (a : Fin r → SliceShape.Axis)
    (v : ∀ d, SliceShape.IsWellFormed (m d) (o d) (a d)),
    (∀ d, p.low d ≤ (a d).start ∧ (a d).limit ≤ (m d : Int) - p.high d ∧
      p.interior d = 0 ∧ (a d).stride = 1) →
    ∃ w : ∀ d, SliceShape.IsWellFormed (s d) (o d) (shifted p a d),
      ∀ {α : Type} (fill : α) (xs : Tensor s α) j,
        tensor p fill xs (IndexMaps.sliceIndex a v j) = xs (IndexMaps.sliceIndex (shifted p a) w j)

def Undo : Prop :=
  ∀ {r : Nat} {s m : Shape r} (p : Params s m) (a : Fin r → SliceShape.Axis)
    (v : ∀ d, SliceShape.IsWellFormed (m d) (s d) (a d)),
    (∀ d, (a d).start = p.low d ∧ (a d).stride - 1 = (p.interior d : Int)) →
    ∀ {α : Type} (fill : α) (xs : Tensor s α) j, tensor p fill xs (IndexMaps.sliceIndex a v j) = xs j

def PaddingOnly : Prop :=
  ∀ {r : Nat} {s m o : Shape r} (p : Params s m) (a : Fin r → SliceShape.Axis)
    (v : ∀ d, SliceShape.IsWellFormed (m d) (o d) (a d)),
    (∃ d, (a d).limit ≤ p.low d ∨ (m d : Int) - p.high d ≤ (a d).start) →
    ∀ {α : Type} (fill : α) (xs : Tensor s α) j, tensor p fill xs (IndexMaps.sliceIndex a v j) = fill
end RevisedBenchmark.SliceOfPad
