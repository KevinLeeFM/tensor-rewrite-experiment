module

public import Std

/-! A necessary validity condition for the paper artifact's convolution padding. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.ConvolutionVacuity

/-- TensorRight evaluates dilation `d` as Pad interior spacing `d - 1`. -/
def nonnegativeInterior {rank : Nat} (dilation : Fin rank → Int) : Prop :=
  ∀ axis, 0 ≤ dilation axis - 1

/-- A nonempty spatial axis group with dilation zero has no valid padded operand. -/
theorem zero_dilation_invalid {rank : Nat} (axis : Fin rank) :
    ¬ nonnegativeInterior (fun _ : Fin rank => 0) := by
  intro valid
  have impossible := valid axis
  change 0 ≤ (0 : Int) - 1 at impossible
  omega

/-- This is an explicit arithmetic certificate for the artifact's fixed value. -/
theorem negative_interior : (0 : Int) - 1 < 0 := by decide

#print axioms zero_dilation_invalid
#print axioms negative_interior

end TensorRewrite.PaperComparison.ConvolutionVacuity
