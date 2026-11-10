module

public import Std

/-! A one-dimensional contraction with unit filter and a uniform Select predicate.
This mathematical-integer model isolates branch-dependent scaling. It does not
model binary32 arithmetic or the C++ graph traversal. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.SelectContraction

/-- Exact contraction against a unit filter, in list order. -/
def sum : List Int → Int
  | [] => 0
  | x :: xs => x + sum xs

/-- Scale each selected input branch before contracting. -/
def branchContraction (predicate : Bool) (xs : List Int) : Int :=
  sum (xs.map fun x => if predicate then 2 * x else 3 * x)

/-- Remove both branch scales, then multiply the contraction by their product. -/
def hoistedContraction (predicate : Bool) (xs : List Int) : Int :=
  (2 * 3) * sum (xs.map fun x => if predicate then x else x)

end TensorRewrite.Pilot.SelectContraction
