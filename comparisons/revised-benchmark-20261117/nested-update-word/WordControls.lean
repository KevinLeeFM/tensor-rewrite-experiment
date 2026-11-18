import WordProof
namespace RevisedBenchmark.NestedUpdateWord

def observe (outer inner : BitVec 64) : List Nat × List Nat :=
  let base : Fin 10 → Nat := fun _ => 0
  let patch : Fin 2 → Nat := fun j => 7 + j.val
  (List.ofFn (install base (install (readWindow 6 (by decide) base outer) patch inner) outer),
   List.ofFn (install base patch (typedStart 4 outer + typedStart 4 inner)))
example : observe (BitVec.ofNat 64 9223372036854775808) 1 = ([0,7,8,0,0,0,0,0,0,0],[0,0,0,0,0,7,8,0,0,0]) := by decide
example : (observe 2 1).1 = (observe 2 1).2 := by decide
example : (observe 9 9).1 = (observe 9 9).2 := by decide
end RevisedBenchmark.NestedUpdateWord
