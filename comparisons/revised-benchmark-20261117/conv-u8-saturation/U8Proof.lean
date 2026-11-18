import U8Spec
namespace RevisedBenchmark.ConvU8
def xs (i : Fin 2) : Byte := if i = 0 then 15 else 16

theorem refuted : ¬ Goal := by
  intro h
  have e := congrFun (h 2 (by decide) xs (fun _ => 16)) 1
  exact (by decide : conv xs (fun _ => 16) 1 ≠ product xs (fun _ => 16) 1) e
#print axioms refuted
end RevisedBenchmark.ConvU8
