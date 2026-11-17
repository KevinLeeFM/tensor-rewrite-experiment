module
public import TensorRewrite.Pilot.ReducerIndexLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.GatherExact
open TensorRewrite.Pilot.ReducerIndex.GatherLiterals

/-- With a positive signed index width, determine when the entire sequential
    chain of narrowed comparison literals agrees with original clamping. -/
def Goal : Prop :=
  ∀ (k extent : Nat),
    (∀ i : BitVec (k+1), selectedIndex extent i = originalIndex extent i) ↔ extent ≤ 2^k
end RevisedBenchmark.GatherExact
