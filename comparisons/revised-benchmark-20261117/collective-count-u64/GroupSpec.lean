import ExchangeSpec
namespace RevisedBenchmark.CollectiveWord
open RevisedBenchmark.Exchange

def reduceAt {g : Nat} {I : Type} (x : Fin (g+1) → I → BitVec 64) (i : I) :=
  ((List.finRange g).map fun r => x r.succ i).foldl (· + ·) (x 0 i)

def folded (g : Nat) (v : BitVec 64) := v * BitVec.ofNat 64 (g+1)

def Goal :=
  (∀ (g : Nat) (_groupFits : g+1 < 2^63) (I : Type) (v : BitVec 64),
      (fun (_r : Fin (g+1)) (i : I) => reduceAt (g := g) (fun _ _ => v) i) =
      fun _ _ => folded g v) ∧
  (∀ (g k : Nat) (_groupFits : g+1 < 2^63) (C : Type) (v : BitVec 64),
      (fun (r : Fin (g+1)) (i : Fin k × C) =>
        reduceAt (g := g) (fun _ (_ : Fin ((g+1)*k) × C) => v) (slot r i.1, i.2)) =
      fun _ _ => folded g v)
end RevisedBenchmark.CollectiveWord
