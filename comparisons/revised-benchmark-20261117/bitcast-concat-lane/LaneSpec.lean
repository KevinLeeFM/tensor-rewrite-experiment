import Std
set_option autoImplicit false
namespace RevisedBenchmark.LaneConcat

/-- Nonempty concatenation of equal shapes, using the specified numeric axis. -/
def concat (copies axis : Nat) (s : List Nat) : Option (List Nat) := do
  if copies = 0 then none else
    let n ← s[axis]?
    return s.set axis (copies*n)

/-- Narrow from one wide storage word to r lanes, concatenate, then widen the final r lanes. -/
def before (r copies : Nat) (s : List Nat) : Option (List Nat) := do
  let inner ← concat copies s.length (s ++ [r])
  if inner.getLast? = some r then return inner.dropLast else none

/-- New concat keeps the numeric dimension from the old concat. -/
def after (copies : Nat) (s : List Nat) := concat copies s.length s

def Preservation : Prop := ∀ (r copies : Nat) (s out : List Nat), 1 < r →
  before r copies s = some out → after copies s = some out

end RevisedBenchmark.LaneConcat
