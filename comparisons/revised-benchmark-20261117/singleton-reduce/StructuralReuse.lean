module
public import SingletonSpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.SingletonReduce.Reuse
open TensorRewrite.Pilot TensorRewrite.Pilot.Reduction

/-- A scalar map preserves the order and multiplicity of every reduction fiber. -/
theorem fiberValues_map {α β : Type} (plan : Plan) (f : α → β)
    (input : Tensor plan.inputShape α) (output : Index plan.outputShape) :
    fiberValues plan (Tensor.map f input) output = (fiberValues plan input output).map f := by
  induction plan with
  | scalar => rfl
  | keep extent tail ih => exact ih _ _
  | reduce extent tail ih =>
    simp only [fiberValues, Tensor.map, List.map_flatMap]
    congr 1
    funext coordinate
    exact ih _ _

/-- Mapping a fold is sound only when the map preserves each operation and initializer. -/
theorem foldl_map_hom {α β : Type} (f : α → β) (operation : α → α → α)
    (target : β → β → β) (hom : ∀ a b, target (f a) (f b) = f (operation a b))
    (values : List α) (initial : α) :
    (values.map f).foldl target (f initial) = f (values.foldl operation initial) := by
  induction values generalizing initial with
  | nil => rfl
  | cons value values ih =>
    simp only [List.map_cons, List.foldl_cons, hom]
    exact ih _

end RevisedBenchmark.SingletonReduce.Reuse
