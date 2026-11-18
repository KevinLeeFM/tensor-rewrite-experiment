import CopySpec
namespace RevisedBenchmark.LayoutConstraint
open CopyChain
-- Operand of the producer's identity, observed at its logical coordinate.
def original {I α : Type} {n} (src : Layout I n) (data : Fin n → α) (i : I) := data (src.address i)
-- Source SameShape forwards storage. Otherwise a Copy is read in the result layout.
def replacement {I α : Type} {n} (same : Bool) (src dst : Layout I n)
    (data : Fin n → α) (i : I) :=
  if same then data (dst.address i) else copy src dst data (dst.address i)

def Goal := ∀ (I α : Type) (n) (same : Bool) (src dst : Layout I n),
    (same = true → ∀ i, src.address i = dst.address i) →
    ∀ data i, original src data i = replacement same src dst data i
end RevisedBenchmark.LayoutConstraint
