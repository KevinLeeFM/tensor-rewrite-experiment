import Std
set_option autoImplicit false
namespace RevisedBenchmark.MaxCbrt

/-- For integral x in [1,7], cbrt(x) lies in [1,2). Compare with exact cubed
midpoints of the output grid. The lower test at the unit binade boundary is
automatic for x≥1. Any midpoint tie is impossible for these integral x. -/
def rounds (p x m : Nat) : Prop :=
  let scale := 2^p
  1 ≤ x ∧ x ≤ 7 ∧ scale ≤ m ∧ m ≤ 2*scale ∧
    (2*m-1)^3 < x*(2*scale)^3 ∧ x*(2*scale)^3 < (2*m+1)^3
instance (p x m : Nat) : Decidable (rounds p x m) := by unfold rounds; infer_instance

/-- Left cbrt rounds in BF16, right in F32. A mixed-precision maximum and the
sunk cbrt both have F32 output. Compare integer significands on the F32 scale. -/
def Case : Prop := ∀ (x y l r out : Nat), rounds 7 x l → rounds 23 y r →
  rounds 23 (max x y) out → max (l*2^16) r = out
end RevisedBenchmark.MaxCbrt
