import BiasSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvBias
def scales (i : Fin 2) : Fin 17 := if i = 0 then 1 else 3
theorem refuted (outer inner : Bool) : ¬ Goal outer inner := by
  intro ok
  have q := ok 2 16777216 (fun _ => 1) (fun _ => 1) scales 1
  cases outer <;> cases inner <;> contradiction
#print axioms refuted
end RevisedBenchmark.ConvBias
