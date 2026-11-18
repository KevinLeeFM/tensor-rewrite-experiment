import PromotionSpec
namespace RevisedBenchmark.ConvPromotion
def witness : Input := fun i => if i = 0 then 257 else 258
theorem refuted : ¬ Preserves := by
  intro h
  have bad := h witness 3 0
  exact (by decide : original witness 3 0 ≠ promoted witness 3 0) bad
#print axioms refuted
end RevisedBenchmark.ConvPromotion
