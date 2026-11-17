module
public import DynamicSpec
public import SignedPadHistorical
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.DynamicPad
open RevisedBenchmark.DynamicSort TensorRewrite.PaperComparison.SignedPad

/-- For zero edges the predicted output descriptor uses the original Pad extent
    on static sizes and upper bounds, or preserves the unbounded marker. -/
def storedOutput (d : Dim) (gap : Nat) : Int :=
  match d with
  | .fixed n | .bounded n => extent n 0 0 gap
  | .unbounded => Dim.unbounded.stored

/-- Rank-one, zero-edge local forwarding guards after the two earlier returns.
    Types/metadata/control checks are taken compatible for the witness. -/
def candidate (d : Dim) (gap : Nat) : Prop :=
  d.stored ≠ 0 ∧ ¬ (0 < gap ∧ d.stored = 1) ∧ storedOutput d gap = d.stored

/-- Which fixed descriptor and interior counts preserve *runtime length* for
    every admitted realization whenever the local value guard fires? -/
def Classification : Prop :=
  ∀ (d : Dim) (gap : Nat),
    (∀ n, d.admits n → candidate d gap → extent n 0 0 gap = (n : Int)) ↔
      d ≠ .unbounded ∨ gap = 0
end RevisedBenchmark.DynamicPad
