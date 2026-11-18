import CopySpec
namespace RevisedBenchmark.DenseChain
open CopyChain
abbrev LayoutN (n : Nat) := Layout (Fin n) n

/-- Each intermediate copy or reshape preserves logical row number and stores
it at that stage's actual physical address. The final operation always executes. -/
def run {n : Nat} {α : Type} (src dst : LayoutN n) :
    List (LayoutN n) → (Fin n → α) → (Fin n → α)
  | [], data => copy src dst data
  | next :: rest, data => run next dst rest (copy src next data)

def ChainGoal := ∀ (n : Nat) (α : Type) (src dst : LayoutN n) (stages) (data : Fin n → α),
    (∀ i, src.address i = dst.address i) → run src dst stages data = data

def ForwardGoal := ∀ (n : Nat) (α : Type) (src dst : LayoutN n) (data : Fin n → α) (i : Fin n),
    copy src dst data (dst.address i) = data (src.address i)
end RevisedBenchmark.DenseChain
