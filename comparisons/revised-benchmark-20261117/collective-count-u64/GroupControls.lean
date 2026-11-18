import GroupProof
namespace RevisedBenchmark.CollectiveWord
example : folded 2 0xffffffffffffffff#64 = 0xfffffffffffffffd#64 := by decide
example : reduceAt (g := 2) (fun _ (_ : Fin 1) => 0xffffffffffffffff#64) 0 =
    0xfffffffffffffffd#64 := by decide
example : reduceAt (g := 1) (fun r (_ : Fin 1) => if r = 0 then 1 else 3) 0 ≠ folded 1 1 := by decide
example : Exchange.slot (2 : Fin 3) (1 : Fin 2) = 5 := by decide
end RevisedBenchmark.CollectiveWord
