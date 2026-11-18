import ScaleSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvSelectScale
theorem refuted (side : Bool) : ¬ Case side := by
  intro all
  have disagree := congrFun (all 2 (by decide) 2 2 (fun _ => 3) (fun _ => 5)
    (fun i => i.val == 0)) 1
  cases side <;> contradiction
#print axioms refuted
end RevisedBenchmark.ConvSelectScale
