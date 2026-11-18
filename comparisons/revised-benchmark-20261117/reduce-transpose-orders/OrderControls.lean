import OrderProof
namespace RevisedBenchmark.ReduceOrders
def labels : Input Int 2 3 2 3 := fun _ i _ j => 10*(i.val : Int) + j.val
example : before true labels 0 (·+·) ⟨2,by decide⟩ ⟨1,by decide⟩ = 48 ∧ direct labels 0 (·+·) 2 1 = 84 := by decide
example : after false labels 5 (·+·) ⟨1,by decide⟩ ⟨2,by decide⟩ = 53 := by decide
example : before true (x:=0) (a:=1) (y:=4) (b:=1) (fun _ _ _ _ => 7) (3:Int) (·+·) ⟨0,by decide⟩ ⟨0,by decide⟩ = 3 := by decide
example : RevisedBenchmark.RadixIota.r32 (16777216+1) = 16777216 := by decide
end RevisedBenchmark.ReduceOrders
