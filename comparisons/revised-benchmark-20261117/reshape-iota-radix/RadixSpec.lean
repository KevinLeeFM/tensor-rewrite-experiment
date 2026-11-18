import Std
set_option autoImplicit false
namespace RevisedBenchmark.RadixIota
structure Digit where
  extent : Nat
  index : Fin extent

/-- Coordinates listed minor-to-major; original rank-one Iota reads the row-major offset. -/
def linear : List Digit → Nat
  | [] => 0
  | d :: ds => d.index.val + d.extent * linear ds
def loop (w : Nat) : List Digit → Nat → BitVec w → BitVec w
  | [], _, acc => acc
  | d :: ds, stride, acc => loop w ds (stride*d.extent)
      (acc + BitVec.ofNat w d.index.val * BitVec.ofNat w stride)
def WordCase : Prop := ∀ (w : Nat) (first : Digit) (rest : List Digit),
  BitVec.ofNat w (linear (first::rest)) =
    loop w rest first.extent (BitVec.ofNat w first.index.val)

/-- Round a nonnegative integer to an integer with at most 24 significant binary digits,
nearest, ties to even. The floating case stays far below exponent overflow. -/
def r32 (n : Nat) : Nat :=
  let ulp := 2^(n.log2-23)
  let q := n / ulp
  let rem := n % ulp
  if 2*rem < ulp ∨ (2*rem = ulp ∧ q%2 = 0) then q*ulp else (q+1)*ulp
def floating (a b : Nat) (i : Fin a) (j : Fin b) :=
  (r32 (i.val*b+j.val), r32 (r32 j.val + r32 (r32 i.val * r32 b)))
def FloatCase : Prop := ∀ (a b : Nat) (_ : 1 < a) (_ : 1 < b) (_ : a*b < 2^26)
    (i : Fin a) (j : Fin b), (floating a b i j).1 = (floating a b i j).2
end RevisedBenchmark.RadixIota
