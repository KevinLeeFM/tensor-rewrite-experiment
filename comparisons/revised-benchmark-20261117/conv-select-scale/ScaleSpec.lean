import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvSelectScale
open RevisedBenchmark.RadixIota
/-- The one-tap, one-input-channel convolution on a single batch or
output channel performs exactly one product per output and starts at +0. -/
def mac (x w : Nat) := r32 (0 + r32 (x * w))
def original (smallIsInput : Bool) (x c a b : Nat) (p : Bool) :=
  let selected := if p then r32 (a*c) else b
  if smallIsInput then mac x selected else mac selected x
def moved (smallIsInput : Bool) (x c a b : Nat) (p : Bool) :=
  let selected := if p then a else b
  if smallIsInput then mac (r32 (x*c)) selected else mac selected (r32 (x*c))
def Case (smallIsInput : Bool) := ∀ n, 1 < n →
  ∀ (x c : Fin 16) (a b : Fin n → Fin 16) (pred : Fin n → Bool),
    (fun i => original smallIsInput x.val c.val (a i).val (b i).val (pred i)) =
    (fun i => moved smallIsInput x.val c.val (a i).val (b i).val (pred i))
end RevisedBenchmark.ConvSelectScale
