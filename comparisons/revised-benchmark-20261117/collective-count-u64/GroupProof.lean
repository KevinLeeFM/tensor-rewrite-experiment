import GroupSpec
import PrefixProof
namespace RevisedBenchmark.CollectiveWord

theorem uniform {I : Type} (g : Nat) (v : BitVec 64) (i : I) :
    reduceAt (g := g) (fun _ _ => v) i = folded g v := by
  simp only [reduceAt, List.map_const', List.length_finRange, WideCount.folded, folded,
    BitVec.ofNat_add, BitVec.mul_add, BitVec.mul_one]
  rw [BitVec.mul_comm (BitVec.ofNat 64 g) v, BitVec.add_comm]

theorem verified : Goal := by
  constructor
  · intro g _ I v
    funext r i
    exact uniform g v i
  · intro g k _ C v
    funext r i
    exact uniform g v (Exchange.slot r i.1, i.2)
#print axioms verified
end RevisedBenchmark.CollectiveWord
