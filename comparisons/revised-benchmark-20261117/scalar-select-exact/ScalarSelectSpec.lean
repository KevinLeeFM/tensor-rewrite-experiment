module
public import TensorRewrite.Pilot.SelectContraction

@[expose] public section
set_option autoImplicit false
namespace RevisedBenchmark.ScalarSelect
open TensorRewrite.Pilot.SelectContraction (sum)

/-- Each cell supplies a predicate and the two alternative unscaled values. -/
structure Cell where
  pred : Bool
  left : Int
  right : Int

/-- Contract the selected, separately scaled branches against a unit filter. -/
def original (a b : Int) (cells : List Cell) : Int :=
  sum (cells.map fun c => if c.pred then a * c.left else b * c.right)

/-- Remove both inner factors and multiply the output by their product. -/
def replaced (a b : Int) (cells : List Cell) : Int :=
  (a*b) * sum (cells.map fun c => if c.pred then c.left else c.right)

/-- Universal exact-integer value preservation for a fixed pair of branch factors. -/
def Boundary : Prop :=
  ∀ a b : Int, (∀ cells, original a b cells = replaced a b cells) ↔
    ((a = 0 ∧ b = 0) ∨ (a = 1 ∧ b = 1))

end RevisedBenchmark.ScalarSelect
