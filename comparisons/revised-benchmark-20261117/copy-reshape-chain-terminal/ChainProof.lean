import ChainSpec
import CopyProof
namespace RevisedBenchmark.DenseChain
open CopyChain

theorem fuse {n : Nat} {α : Type} (src dst : LayoutN n) (stages) (data : Fin n → α) :
    run src dst stages data = copy src dst data := by
  induction stages generalizing src data with
  | nil => rfl
  | cons next rest ih =>
    rw [run, ih]
    exact (CopyChain.verified _ _ _ src next dst data).1

theorem raw_verified : ChainGoal := by
  intro n α src dst stages data same
  rw [fuse]
  funext addr
  change data (src.address (dst.coordinate addr)) = data addr
  rw [same, dst.encode_decode]

theorem forward_verified : ForwardGoal := by
  intro n α src dst data i
  simp [copy, dst.decode_encode]
#print axioms raw_verified
#print axioms forward_verified
end RevisedBenchmark.DenseChain
