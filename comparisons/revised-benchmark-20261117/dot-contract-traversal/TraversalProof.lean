import TraversalSpec
namespace RevisedBenchmark.DotTraversal
def data (k : Fin 4) := if k.val = 2 then 2^24 else if k.val = 3 then 0 else 1
def weights (k : Fin 4) := if k.val = 3 then 2 else 1
theorem refuted (side : Bool) : ¬ Goal side := by
  intro h
  have hx : ∀ i, data i ≤ 2^24 := by decide
  have hw : ∀ i, weights i ≤ 2 := by decide
  have e := h data weights hx hw
  cases side with
  | false => exact (by decide : old false data weights ≠ newDot false data weights) e
  | true => exact (by decide : old true data weights ≠ newDot true data weights) e
#print axioms refuted
end RevisedBenchmark.DotTraversal
