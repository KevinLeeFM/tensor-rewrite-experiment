import Std
namespace RevisedBenchmark.ReduceBase
/-- Shape [inputRows,n] mapped to outer [outputRows,n] on axes [0,1].
The full reduction is on axis 0. Its result has shape [n]. -/
structure Plan where
  inputRows : Nat
  outputRows : Nat
  allowed : inputRows = 1 ∨ inputRows = outputRows

def original (p : Plan) {n : Nat} (read : Nat → Fin n → Int) (c : Fin n) : Int :=
  ((List.range p.outputRows).map (fun i => read (if p.inputRows = 1 then 0 else i) c)).sum
def replacement (p : Plan) {n : Nat} (read : Nat → Fin n → Int) (c : Fin n) : Int :=
  ((List.range p.inputRows).map (fun i => read i c)).sum
def Goal := ∀ p n (read : Nat → Fin n → Int), original p read = replacement p read
end RevisedBenchmark.ReduceBase
