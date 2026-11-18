import Std

set_option autoImplicit false

namespace RevisedBenchmark.BroadcastDot

/-- Enumerate all the bounded positions on one named axis. -/
def sumAxis {n : Nat} (f : Fin n → Int) : Int := (List.ofFn f).sum

/-- Operand roles distinguish the left and right source branches. -/
def product (fromRight : Bool) (source partner : Int) : Int :=
  if fromRight then partner * source else source * partner

/-- Shapes [m,n] and [m,n,n]. Both operands contract original axis 0 and axis 1.
    Broadcasting the vector on dimension 1 discards the first coordinate. -/
def original {m n : Nat} (fromRight : Bool) (x : Fin n → Int)
    (y : Fin m → Fin n → Fin n → Int) (free : Fin n) : Int :=
  sumAxis fun (i : Fin m) =>
    sumAxis fun (k : Fin n) => product fromRight (x k) (y i k free)

/-- Reducing original axis 0 leaves original axes 1 and 2 in order. -/
def reduceFirst {m n : Nat} (y : Fin m → Fin n → Fin n → Int)
    (first second : Fin n) : Int := sumAxis fun i => y i first second

/-- 'to_index' for the retained pair is 1. On the reduced partner this chooses
    its second axis. Its first coordinate is therefore the result coordinate. -/
def replacement {m n : Nat} (fromRight : Bool) (x : Fin n → Int)
    (y : Fin m → Fin n → Fin n → Int) (free : Fin n) : Int :=
  sumAxis fun (k : Fin n) => product fromRight (x k) (reduceFirst y free k)

/-- Positive extents bypass empty-dot handling. With no residual broadcast,
    threshold multiplier one and option value two, compare the exact dot costs
    after cancellation of the common FMA factor. -/
def admitted (m n : Nat) : Prop := 0 < m ∧ 0 < n ∧ n * (m*n) > 2 * (n*n)

/-- Universal equivalence on this well-typed family with same-shaped outputs. -/
def Law (fromRight : Bool) : Prop :=
  ∀ (m n : Nat), admitted m n → ∀ (x : Fin n → Int)
    (y : Fin m → Fin n → Fin n → Int) (free : Fin n),
    original fromRight x y free = replacement fromRight x y free

/-- Each source orientation separately has an admitted counterexample. -/
def Case : Prop := ∀ fromRight : Bool, ¬ Law fromRight

end RevisedBenchmark.BroadcastDot
