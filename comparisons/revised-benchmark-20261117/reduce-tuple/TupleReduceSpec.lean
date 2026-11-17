module
public import TensorRewrite.Pilot.ReductionRules
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.TupleReduce
open TensorRewrite.Pilot TensorRewrite.Pilot.LinearIndex TensorRewrite.Pilot.Reduction

/-- Reassemble a whole heterogeneous state at each input position, fold once,
    then read the resulting components into the outer tuple of tensors. -/
def original {k : Nat} {A : Fin (k+1) → Type} (p : Plan)
    (op : ((c : Fin (k+1)) → A c) → ((c : Fin (k+1)) → A c) → ((c : Fin (k+1)) → A c))
    (init : (c : Fin (k+1)) → A c) (xs : (c : Fin (k+1)) → Tensor p.inputShape (A c)) :
    (c : Fin (k+1)) → Tensor p.outputShape (A c) :=
  fun c j => reduceTensor p op init (fun i a => xs a i) j c

/-- Exact tuple arm of the zero-element dispatch at the typed-value level. -/
def EmptyGoal : Prop :=
  ∀ {k : Nat} {A : Fin (k+1) → Type} (p : Plan) (op) (init) (xs),
    (elementCount p.inputShape = 0 ∨ elementCount p.outputShape = 0) →
    original (A := A) p op init xs = fun c => Tensor.constant (init c)

/-- For a fixed plan, removing a tuple reduction for all inputs is equivalent
    to empty output or a left identity on whole states, permitting coupling. -/
def SameGoal : Prop :=
  ∀ {k : Nat} {A : Fin (k+1) → Type} (p : Plan) (op) (init)
    (same : elementCount p.inputShape = elementCount p.outputShape),
    (∀ xs, original (A := A) p op init xs =
      fun c => Reshape.reshapeTensor (xs c) p.outputShape same) ↔
      elementCount p.outputShape = 0 ∨ ∀ x, op init x = x
end RevisedBenchmark.TupleReduce
