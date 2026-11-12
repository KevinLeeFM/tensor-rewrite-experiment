module

public import TensorRewrite.Pilot.SliceShape

/-! A concrete well-formedness counterexample to the paper's slice/reverse rule. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.ReverseSliceFailure

open Pilot.SliceShape

/-- Grisette's `divOr 0` for a concrete positive stride. -/
def divOrZero (a b : Int) : Int := if b = 0 then 0 else a / b

/-- Grisette's `modOr 0` for a concrete positive stride. -/
def modOrZero (a b : Int) : Int := if b = 0 then 0 else a % b

/-- The exact `count` expression in the paper artifact's `slice/rule13`. -/
def paperCount (start limit stride : Int) : Int :=
  if modOrZero (limit - start) stride = 0 then
    divOrZero (limit - start) stride - 1
  else divOrZero (limit - start) stride

/-- The exact RHS bounds required by the paper's two explicit preconditions. -/
def paperReplacement (extent : Int) (axis : Axis) : Axis :=
  let newStart := axis.start + axis.stride * paperCount axis.start axis.limit axis.stride + 1 -
    extent
  let candidateEnd := newStart + axis.limit - axis.start
  { start := newStart, limit := if extent ≥ candidateEnd then candidateEnd else extent,
    stride := axis.stride }

/-- The original slice is legal and has an accessible first output element. -/
theorem lhs_valid :
    IsWellFormed 10 3 ⟨2, 8, 2⟩ ∧ 0 < (3 : Nat) ∧ 2 + 2 * (0 : Int) < 10 := by
  decide

/-- The paper's stipulated replacement starts at -3 and fails its Slice validity check. -/
theorem rhs_invalid :
    paperReplacement 10 ⟨2, 8, 2⟩ = ⟨-3, 3, 2⟩ ∧
      ¬ IsWellFormed 10 3 (paperReplacement 10 ⟨2, 8, 2⟩) := by
  decide

#print axioms lhs_valid
#print axioms rhs_invalid

end TensorRewrite.PaperComparison.ReverseSliceFailure
