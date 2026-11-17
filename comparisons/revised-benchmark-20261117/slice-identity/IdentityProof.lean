module
public import IdentitySpec
public section
set_option autoImplicit false
namespace RevisedBenchmark.StaticIdentity
open TensorRewrite.Pilot
/-- Looking at the last legal position bounds the displacement at every output position. -/
theorem forward : Goal := by
  intro r s a v α x
  funext j
  apply congrArg x
  funext k
  apply Fin.ext
  have lookup := IndexMaps.sliceIndex_val a v j k
  have bounded : ((j k).val : Int) < (s k : Int) := by exact_mod_cast (j k).isLt
  have last := (SliceShape.coordinate_bounds (v k) ((s k : Int) - 1)
    (by omega) (by omega)).2
  have start := (v k).1
  have positive := (v k).2.2.2.1
  have step := Int.mul_le_mul_of_nonneg_left
    (show ((j k).val : Int) ≤ (s k : Int) - 1 by omega)
    (show 0 ≤ (a k).stride - 1 by omega)
  have low := Int.mul_nonneg (show 0 ≤ (a k).stride - 1 by omega)
    (show 0 ≤ ((j k).val : Int) by omega)
  simp only [Int.sub_mul, Int.one_mul] at step low
  exact_mod_cast (show (((IndexMaps.sliceIndex a v j k).val : Nat) : Int) =
    ((j k).val : Int) by omega)

example : SliceShape.IsWellFormed 1 1 ⟨0,1,7⟩ := by decide
example : SliceShape.IsWellFormed 0 0 ⟨0,0,7⟩ := by decide
example : ¬ SliceShape.IsWellFormed 3 3 ⟨1,3,1⟩ := by decide
#check (forward : Goal)
#print axioms forward
end RevisedBenchmark.StaticIdentity
