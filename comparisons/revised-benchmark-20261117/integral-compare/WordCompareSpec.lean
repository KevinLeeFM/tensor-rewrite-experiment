module
public import TensorRewrite.Pilot.Tensor
@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.WordCompare
open TensorRewrite.Pilot
def key {w : Nat} (signed : Bool) (x : BitVec w) : Int :=
  if signed then x.toInt else (x.toNat : Int)

inductive Direction | lt | le | gt | ge | eq | ne
def cmp {w : Nat} (s : Bool) (d : Direction) (a b : BitVec w) : Bool :=
  match d with
  | .lt => decide (key s a < key s b)
  | .le => decide (key s a ≤ key s b)
  | .gt => decide (key s b < key s a)
  | .ge => decide (key s b ≤ key s a)
  | .eq => decide (a = b)
  | .ne => decide (a ≠ b)
def selfResult : Direction → Bool
  | .lt | .gt | .ne => false
  | .le | .ge | .eq => true

def Self : Prop := ∀ {r w : Nat} (sh : Shape r) (signed : Bool) (d : Direction)
    (x : Tensor sh (BitVec w)), Tensor.map₂ (cmp signed d) x x = Tensor.constant (selfResult d)

def lowerBounds {w : Nat} (threshold x : BitVec w) : Prop :=
  cmp false .lt x threshold = false ∧ cmp false .ge x threshold = true ∧
  cmp false .gt threshold x = false ∧ cmp false .le threshold x = true

def UnsignedBoundary : Prop := ∀ {r w : Nat} (sh : Shape r) (threshold : Tensor sh (BitVec w)),
  (∀ (x : Tensor sh (BitVec w)) i, lowerBounds (threshold i) (x i)) ↔
    threshold = Tensor.constant 0

def maxWord {w : Nat} (s : Bool) (a b : BitVec w) :=
  if key s a ≤ key s b then b else a
def minWord {w : Nat} (s : Bool) (a b : BitVec w) :=
  if key s a ≤ key s b then a else b

def Extreme : Prop := ∀ {w : Nat} (s : Bool) (a b : BitVec w),
    cmp s .gt (maxWord s a b) a = cmp s .gt b a ∧
    cmp s .gt (maxWord s a b) b = cmp s .gt a b ∧
    cmp s .gt a (minWord s a b) = cmp s .gt a b ∧
    cmp s .gt b (minWord s a b) = cmp s .gt b a
end RevisedBenchmark.WordCompare
