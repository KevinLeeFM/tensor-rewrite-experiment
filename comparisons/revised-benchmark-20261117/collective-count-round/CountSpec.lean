import RadixSpec
import ExchangeSpec
namespace RevisedBenchmark.CollectiveCount
open RevisedBenchmark.RadixIota
open RevisedBenchmark.Exchange

def reduceAt {g : Nat} {I : Type} (x : Fin (g+1) → I → Nat) (i : I) :=
  (List.finRange g).foldl (fun acc r => r32 (acc + x r.succ i)) (x 0 i)

def folded (g v : Nat) := r32 (v * r32 (g+1))

def All := ∀ (g : Fin 16) (v : Fin (2^24+1)) (i : Fin 2),
  reduceAt (g := g.val) (fun _ (_ : Fin 2) => v.val) i = folded g.val v.val

def Scatter := ∀ (g : Fin 16) (v : Fin (2^24+1)) (k : Nat)
    (r : Fin (g.val+1)) (i : Fin k),
  reduceAt (g := g.val) (fun _ (_ : Fin ((g.val+1)*k)) => v.val) (slot r i) =
    folded g.val v.val
end RevisedBenchmark.CollectiveCount
