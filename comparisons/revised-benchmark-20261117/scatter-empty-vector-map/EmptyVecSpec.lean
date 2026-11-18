import Std
namespace RevisedBenchmark.EmptyVecMap

/-- Explicit index vectors have zero lanes. The sole operand axis has no
start component, and is an inserted window dimension at offset zero. -/
def target (vector : Fin 0 → Int) : Int :=
  ((List.finRange 0).map vector).sum + 0

abbrev Word := BitVec 32
def scatter {n : Nat} (base updates : Fin n → Word)
    (indices : Fin n → Fin 0 → Int) (o : Fin n) : Word :=
  (List.finRange n).foldl (fun v batch =>
    if target (indices batch) = (o.val : Int) then v + updates batch else v) (base o)
def replacement {n : Nat} (base updates : Fin n → Word) (o : Fin n) := base o + updates o

def Goal := ∀ (n : Nat), 0 < n → ∀ (base updates : Fin n → Word)
  (indices : Fin n → Fin 0 → Int), scatter base updates indices = replacement base updates
end RevisedBenchmark.EmptyVecMap
