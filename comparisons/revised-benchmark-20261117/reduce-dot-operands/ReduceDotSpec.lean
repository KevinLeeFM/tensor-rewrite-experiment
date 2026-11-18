import Std

set_option autoImplicit false

namespace RevisedBenchmark.ReduceDotOperands

/-- Add reduction over a finite static axis, with zero seed (the empty sum). -/
def addZero {n : Nat} (f : Fin n → Int) : Int := (List.ofFn f).sum

/-- Exact integer arrays on [free,2,2]. -/
abbrev Operand (free : Nat) := Fin free → Fin 2 → Fin 2 → Int

/-- Reduce both output axes of a dot pairing lhs [1,2] with rhs [2,1]. -/
def original {m n : Nat} (a : Operand m) (b : Operand n) : Int :=
  addZero fun i => addZero fun j =>
    addZero fun p => addZero fun q => a i p q * b j q p

/-- Physical-order membership scans produce contracting lists [0,1] and [0,1]
after input axis 0 on each side has been reduced. -/
def replacement {m n : Nat} (a : Operand m) (b : Operand n) : Int :=
  addZero fun p => addZero fun q =>
    (addZero fun i => a i p q) * (addZero fun j => b j p q)

/-- Original dot uses four FMAs per cell. Then reduce m*n cells to one. -/
def oldCost (m n : Nat) : Nat := 2 * 4 * (m*n) + (m*n - 1)

/-- Each reduced operand has four cells, then a scalar dot uses four FMAs. -/
def newCost (m n : Nat) : Nat := 4 * (m-1) + 4 * (n-1) + 2 * 4

/-- Nonempty, nontrivial scalar-output reduction and strict threshold two. -/
def admitted (m n : Nat) : Prop :=
  0 < m ∧ 0 < n ∧ 1 < m*n ∧ oldCost m n > 2 * newCost m n

/-- Refutation of universal scalar value preservation on the declared family. -/
def Case : Prop := ¬ ∀ (m n : Nat), admitted m n →
  ∀ (a : Operand m) (b : Operand n), original a b = replacement a b

end RevisedBenchmark.ReduceDotOperands
