module
public import TensorRewrite.Pilot.Tensor
public import DynamicSpec
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.IotaZero
open TensorRewrite.Pilot RevisedBenchmark.DynamicSort
def Static : Prop := ∀ {r : Nat} (s : Shape r) (k : Fin r),
  (∀ j : Index s, (j k).val = 0) ↔ (Nonempty (Index s) → s k ≤ 1)
def Runtime : Prop := ∀ d : Dim,
  (∀ n : Nat, d.admits n → d.stored ≤ 1 → ∀ i : Fin n, i.val = 0) ↔ d ≠ .unbounded
end RevisedBenchmark.IotaZero
