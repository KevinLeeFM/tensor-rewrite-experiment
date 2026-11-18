import RadixSpec
set_option autoImplicit false
namespace RevisedBenchmark.ConvBias
open RevisedBenchmark.RadixIota
def plus (flip : Bool) (a b : Nat) := r32 (if flip then b+a else a+b)
def times (flip : Bool) (a b : Nat) := r32 (if flip then b*a else a*b)
def conv (input kernel : Nat) := plus false 0 (times false input kernel)
def old (outer inner : Bool) (input kernel bias scale : Nat) :=
  times outer (plus inner (conv input kernel) bias) scale
def newValue (input kernel bias scale : Nat) :=
  plus false (conv input (times false kernel scale)) (times false bias scale)
def Goal (outer inner : Bool) := ∀ (n : Nat) (x : Fin (2^24+1))
  (kernel bias scale : Fin n → Fin 17), ∀ i : Fin n,
  old outer inner x.val (kernel i).val (bias i).val (scale i).val =
    newValue x.val (kernel i).val (bias i).val (scale i).val
end RevisedBenchmark.ConvBias
