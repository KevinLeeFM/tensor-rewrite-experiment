module

public import TensorRewrite.Pilot.FiniteProduct

@[expose] public section
set_option autoImplicit false
namespace TensorRewrite.Heldout.MixedRadix3
open Pilot
/-- Rank-one natural-valued Iota reads its bounded coordinate. -/
def sourceIota {n : Nat} (i : Fin n) : Nat := i.val
/-- Row-major reshape of rank-one Iota to [a,b,c], via existing bounded packing. -/
def original {a b c : Nat} (i : Fin a) (j : Fin b) (k : Fin c) : Nat :=
  sourceIota (FiniteProduct.join i (FiniteProduct.join j k))
/-- Exact iteration order of the source replacement for three output dimensions. -/
def replacement {a b c : Nat} (i : Fin a) (j : Fin b) (k : Fin c) : Nat :=
  (k.val + c * j.val) + (c * b) * i.val
/-- Source-partition guards, distinct from the desired rewrite conclusion. -/
def admissible (a b c : Nat) : Prop := 1 < a ∧ 1 < b ∧ 1 < c
/-- Frozen narrow model target; not the entire XLA branch. -/
def Goal : Prop := ∀ (a b c : Nat), admissible a b c →
  ∀ (i : Fin a) (j : Fin b) (k : Fin c), original i j k = replacement i j k
end TensorRewrite.Heldout.MixedRadix3
