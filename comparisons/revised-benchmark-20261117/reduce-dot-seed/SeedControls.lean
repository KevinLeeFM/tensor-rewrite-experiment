import SeedProof
namespace RevisedBenchmark.BatchSeed
example : newDot 2 2 (fun _ _ _ => 1) (fun _ _ => 1) 0 = 4 := by decide
example : 5 + sum 2 (fun b => oldDot 2 (fun _ _ _ => 1) (fun _ _ => 1) b 0) = 9 := by decide
example : 5 + sum 2 (fun f => newDot 2 2 (fun _ _ _ => 1) (fun _ _ => 1) f) = 13 := by decide
example : 5 + sum 0 (fun f => newDot 2 0 (fun _ _ _ => 7) (fun _ _ => 3) f) = 5 := by decide
end RevisedBenchmark.BatchSeed
