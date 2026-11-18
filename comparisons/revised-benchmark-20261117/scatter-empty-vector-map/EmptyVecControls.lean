import EmptyVecProof
namespace RevisedBenchmark.EmptyVecMap
example : (scatter base updates noLanes 0, scatter base updates noLanes 1) = (8,0) := by decide
example : (replacement base updates 0, replacement base updates 1) = (3,5) := by decide
example : scatter base (fun i => if i = 0 then 5 else 3) noLanes 0 = 8 := by decide
example : scatter (n := 1) (fun _ => 4) (fun _ => 5) noLanes 0 = 9 := by decide
example : replacement (n := 1) (fun _ => 4) (fun _ => 5) 0 = 9 := by decide
#check (refuted : ¬ Goal)
end RevisedBenchmark.EmptyVecMap
