import Std
namespace RevisedBenchmark.MixedTapCount

inductive Kind | byte | word deriving DecidableEq
def bound : Kind → Nat | .byte => 2^8 | .word => 2^32
def widen {k : Kind} (x : Fin (bound k)) := BitVec.ofNat 32 x.val

/-- The operands are uniform-valued parameters; reversing a full kernel
with identical entries leaves the same list of term values. -/
def kernelTerms {α : Type} (reverse : Bool) (n : Nat) (v : α) :=
  let xs := List.replicate n v
  if reverse then xs.reverse else xs

def old {a b} (rev : Bool) (n : Nat) (x : Fin (bound a)) (w : Fin (bound b)) :=
  let v := (widen x).zeroExtend 64 * (widen w).zeroExtend 64
  let acc := (kernelTerms rev n v).foldl (·+·) 0
  BitVec.ofNat 32 (min acc.toNat (2^32-1))

def newValue {a b} (rev : Bool) (n : Nat) (x : Fin (bound a)) (w : Fin (bound b)) :=
  (kernelTerms rev n (widen x * widen w)).foldl (·+·) 0

def Claim (a b : Kind) (rev : Bool) := ∀ n, 1 < n → ∀ x w,
  @old a b rev n x w = @newValue a b rev n x w
end RevisedBenchmark.MixedTapCount
