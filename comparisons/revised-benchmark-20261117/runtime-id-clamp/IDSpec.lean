import Std
namespace RevisedBenchmark.IDClamp
inductive Kind where | replica | partition
def bound (k : Kind) (replicas partitions : Nat) :=
  match k with | .replica => replicas | .partition => partitions
def eligible (n : Nat) (upper : BitVec 32) := n != 1 && decide (n ≤ upper.toNat + 1)
def original (hi x : BitVec 32) := BitVec.ofNat 32 (min (max 0 x.toNat) hi.toNat)
def Goal := ∀ k r p hi, eligible (bound k r p) hi = true →
  ∀ x : Fin (bound k r p), original hi (BitVec.ofNat 32 x.val) = BitVec.ofNat 32 x.val
end RevisedBenchmark.IDClamp
