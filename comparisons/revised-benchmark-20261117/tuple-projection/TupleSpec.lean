module
public import Std
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleProjection
universe u v
/-- Materialize tuple values in operand order. A tag can carry a complete
    semantic type or shape; payload types may differ between components. -/
def makeTuple {Tag : Type u} {Payload : Tag → Type v} {n : Nat}
    (tags : Fin n → Tag) (operands : (i : Fin n) → Payload (tags i)) :
    List (Sigma Payload) :=
  List.ofFn fun i => ⟨tags i, operands i⟩

/-- Lookup in the constructed tuple preserves the selected operand's tag
    and value for every valid projection. -/
def Goal : Prop :=
  ∀ {Tag : Type u} {Payload : Tag → Type v} {n : Nat}
    (tags : Fin n → Tag) (operands : (i : Fin n) → Payload (tags i)) (i : Fin n),
    (makeTuple tags operands)[i.val]? = some ⟨tags i, operands i⟩
end RevisedBenchmark.TupleProjection
