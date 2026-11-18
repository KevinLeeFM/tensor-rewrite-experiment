import PairProof
namespace RevisedBenchmark.ScatterPair
example : ¬ Case true .cu .cc := by rw [criterion]; decide
example : ¬ Case false .uu .uc := by rw [criterion]; decide
example : Case true .uc .cu := by rw [criterion]; decide
example : after false .uu .cc (fun _ : Fin 3=>1) (fun _=>2) 0 1 3 5 2 = 3 := by decide
end RevisedBenchmark.ScatterPair
