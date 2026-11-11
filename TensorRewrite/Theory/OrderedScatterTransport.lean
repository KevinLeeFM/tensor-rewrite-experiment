module

public import TensorRewrite.Theory.OrderedScatterProof
public import TensorRewrite.Pilot.ReducerIndexLemmas
public import TensorRewrite.Pilot.OperandOrderLemmas

/-! Actual update-data transport and independently checked reducer parameter roles. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.OrderedScatter

open Pilot

/-- Mapping update states changes payloads alone in the actual geometry-derived event trace. -/
theorem entries_map {rank batchRank indexSize : Nat} {α β : Type}
    (plan : Plan rank batchRank indexSize) (convert : α → β)
    (indices : Tensor plan.batchShape (Fin indexSize → Int))
    (updates : Tensor plan.batchShape (Tensor plan.windowShape α)) :
    entries plan indices (fun batch => Tensor.map convert (updates batch)) =
      (entries plan indices updates).map (Entry.mapValue convert) := by
  simp [entries, List.map_flatMap, List.map_map, Function.comp_def, Tensor.map, Entry.mapValue]

/-- Distinct parameter roles make the actual word update function ordinary addition. -/
theorem distinct_word_operation {width : Nat}
    (first second : ReducerIndex.ScatterRoles.Parameter) (distinct : first ≠ second) :
    (ReducerIndex.ScatterRoles.combine first second : BitVec width → BitVec width → BitVec width) =
      (fun a b => a + b) := by
  cases first <;> cases second
  · exact False.elim (distinct rfl)
  · rfl
  · funext a b
    exact BitVec.add_comm b a
  · exact False.elim (distinct rfl)

end TensorRewrite.Theory.OrderedScatter
