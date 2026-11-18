module
public import TensorRewrite.Pilot.Tensor

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ArgReuse
open TensorRewrite.Pilot

/-- Endpoints encode infinities. Interior ranks are distinct ordered numbers;
none is the single observable NaN. -/
abbrev Value (n : Nat) := Option (Fin (n + 2))

/-- Which extremum the original and sibling reductions calculate. -/
inductive Direction where | maximum | minimum
deriving DecidableEq

/-- Standalone reduction uses numeric min/max with absorbing NaN. -/
def valueStep {n : Nat} (d : Direction) : Value n → Value n → Value n
  | some x, some y => some (match d with | .maximum => max x y | .minimum => min x y)
  | _, _ => none

/-- Strict comparison or left self-inequality, as in the matched value select. -/
def preferLeft {n : Nat} (d : Direction) : Value n → Value n → Bool
  | none, _ => true
  | some _, none => false
  | some x, some y => match d with | .maximum => decide (y < x) | .minimum => decide (x < y)

/-- Numeric equality used by the index tie-breaker. A NaN is unequal to itself. -/
def numericEq {n : Nat} : Value n → Value n → Bool
  | some x, some y => decide (x = y)
  | _, _ => false

/-- The variadic reduction carries independent value and index selects. -/
def argStep {n : Nat} (d : Direction) (a b : Value n × Nat) : Value n × Nat :=
  let pred := preferLeft d a.1 b.1
  (if pred then a.1 else b.1,
   if pred || (numericEq a.1 b.1 && decide (a.2 < b.2)) then a.2 else b.2)

/-- Use negative infinity for maximum and positive infinity for minimum. -/
def seed (n : Nat) (d : Direction) : Value n :=
  some (match d with | .maximum => 0 | .minimum => Fin.last (n+1))

/-- For every bounded input, output shape, ordered reduction fiber and iota axis,
standalone reduction yields exactly tuple component zero of the sibling reduction. -/
def Goal : Prop :=
  ∀ (n ri ro : Nat) (s : Shape ri) (t : Shape ro) (x : Tensor s (Value n))
    (fiber : Index t → List (Index s)) (axis : Fin ri) (d : Direction),
    (fun o => (fiber o).foldl (fun acc i => valueStep d acc (x i)) (seed n d)) =
    (fun o => ((fiber o).foldl (fun acc i => argStep d acc (x i, (i axis).val))
      (seed n d, 0)).1)

end RevisedBenchmark.ArgReuse
