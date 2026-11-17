module
public import TensorRewrite.Pilot.ConstantGuardLemmas
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.CompareGuards
open TensorRewrite.Pilot
def PredGuards : Prop := ∀ {r : Nat} (s : Shape r) (g : ConstantGuard.View r s)
    (x : Tensor s Bool),
    (g.isAll false = true →
      (fun i => decide (x i ≠ g.eval i)) = x ∧ (fun i => decide (g.eval i ≠ x i)) = x) ∧
    (g.isAll true = true →
      (fun i => decide (x i = g.eval i)) = x ∧ (fun i => decide (g.eval i = x i)) = x)

def causal {r : Nat} {s : Shape r} {α : Type} [DecidableEq α] (p : Tensor s Bool)
    (yes no rhs : Tensor s α) : Tensor s Bool := fun i =>
  decide ((if p i then yes i else no i) ≠ rhs i)

def CausalBoundary : Prop := ∀ {r : Nat} (s : Shape r) (α : Type) [DecidableEq α]
    (yes no rhs : Tensor s α), (∀ p, causal p yes no rhs = p) ↔
    ∀ i, yes i ≠ rhs i ∧ no i = rhs i

def CausalPred : Prop := ∀ {r : Nat} (s : Shape r) (yes no rhs : ConstantGuard.View r s)
    (p : Tensor s Bool), yes.isAll true = true → no.isAll false = true →
    rhs.isAll false = true → causal p yes.eval no.eval rhs.eval = p
end RevisedBenchmark.CompareGuards
