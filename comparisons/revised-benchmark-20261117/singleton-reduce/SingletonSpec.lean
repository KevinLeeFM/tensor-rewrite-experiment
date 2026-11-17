module
public import TensorRewrite.Pilot.Reduction
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.SingletonReduce
open TensorRewrite.Pilot TensorRewrite.Pilot.Reduction

/-- A one-result tuple-root reducer consumes scalar accumulator and element
    arguments. Its scalar clone returns the operand of the singleton root. -/
def Goal : Prop :=
  ∀ {α : Type} (p : Plan) (body : α → α → (Fin 1 → α)) (init : α)
    (xs : Tensor p.inputShape α),
    (fun (c : Fin 1) (j : Index p.outputShape) =>
      reduceTensor p (fun a b => body (a 0) (b 0)) (fun _ : Fin 1 => init)
        (fun i (_ : Fin 1) => xs i) j c) =
    (fun (_ : Fin 1) => reduceTensor p (fun a b => body a b 0) init xs)
end RevisedBenchmark.SingletonReduce
