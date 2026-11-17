module
public import SignedPadHistorical
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.CompatiblePad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
/-- The source flag tests only edge padding. With equal static shapes and
    zero edges, every observed input coordinate survives even if a singleton
    axis has nonzero interior padding. -/
def Goal : Prop :=
  ∀ {r : Nat} {s : Shape r} (p : Params s s),
    (∀ d, p.low d = 0 ∧ p.high d = 0) →
    ∀ {α : Type} (fill : α) (xs : Tensor s α), tensor p fill xs = xs
end RevisedBenchmark.CompatiblePad
