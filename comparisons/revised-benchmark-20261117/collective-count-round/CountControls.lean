import CountProof
namespace RevisedBenchmark.CollectiveCount
example : reduceAt (g := 5) (fun _ (_ : Fin 2) => 4194305) 1 = 25165828 := by decide
example : folded 5 4194305 = 25165830 := by decide
example : reduceAt (g := 3) (fun _ (_ : Fin 2) => 5) 0 = folded 3 5 := by decide
example : reduceAt (g := 0) (fun _ (_ : Fin 2) => 4194305) 0 = folded 0 4194305 := by decide
example : Exchange.slot (4 : Fin 6) (1 : Fin 2) = 9 := by decide
end RevisedBenchmark.CollectiveCount
