import PadProof
set_option autoImplicit false
namespace Auxiliary.DebugPad
private def c (n : Int) : V 1 := fun _ => n
private def x (q : V 1) := 10 + q 0
example : nestedGoal := verified
example : lowGoal := low_verified
-- Two inner data elements at positions 1,3. Outer low crop -1 moves them to 0,2.
example : pad (c 5) (c (-1)) zero 99 (pad (c 2) (c 1) (c 1) 99 x) (c 2) = 11 ∧
          pad (c 2) (c 0) (c 1) 99 x (c 1) = 99 := by decide
example : pad (c 0) (c 1) (c 3) 99 x (c 0) = 99 := by decide
-- Dropping the nonnegative inner-low guard loses the already cropped first data element.
example : pad (c 1) (c 1) zero 99 (pad (c 2) (c (-1)) zero 99 x) (c 0) = 99 ∧
          pad (c 2) (c 0) zero 99 x (c 0) = 10 := by decide
end Auxiliary.DebugPad
