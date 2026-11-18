import PromotionSpec
import NestedSpec
set_option autoImplicit false
namespace RevisedBenchmark.DotResult
open NestedDot
abbrev Data := Nat → Nat → Nat
def operand (x : Data) : Matrix := fun i j => rounded (ConvPromotion.bf (x i j))
def narrow (m : Matrix) : Matrix := fun i j => (m i j).map ConvPromotion.bf
def old (lhsInner : Bool) (k n : Nat) (a b c : Matrix) :=
  if lhsInner then dot n (narrow (dot k a b)) c else dot k a (narrow (dot n b c))
def new (lhsInner : Bool) (k n : Nat) (a b c : Matrix) :=
  if lhsInner then right k n a b c else left k n a b c
def Goal (lhsInner : Bool) := ∀ m k n p : Nat, 0 < k → 0 < n →
  (if lhsInner then leftCost m k n p > 2*rightCost m k n p
   else rightCost m k n p > 2*leftCost m k n p) →
  ∀ (a b c : Data) (i : Fin m) (j : Fin p) (u v : Nat),
  old lhsInner k n (operand a) (operand b) (operand c) i j = some u →
  new lhsInner k n (operand a) (operand b) (operand c) i j = some v → u=v
end RevisedBenchmark.DotResult
