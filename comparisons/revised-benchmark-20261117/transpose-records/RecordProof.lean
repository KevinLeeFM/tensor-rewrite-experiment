import RecordSpec
import TransProof
set_option autoImplicit false
namespace RevisedBenchmark.TransposeRecords
open TensorRewrite.Pilot Tensor RevisedBenchmark.TransArrays

theorem identityRecord : IdentityRecord := by
  intro n p sorted
  let label : Shape n := fun i => i.val
  obtain ⟨labels, _⟩ := sortedForward label (permuteAxes p label) p
    (fun i => congrArg label (p.output_input i)) sorted
  have fixed (j : Fin n) : p.outputToInput j = j :=
    Fin.ext (congrFun labels j)
  constructor
  · intro A a
    exact funext fun j => congrArg a (fixed j)
  · intro s
    exact sortedForward s (permuteAxes p s) p
      (fun i => congrArg s (p.output_input i)) sorted

theorem composeRecord : ComposeRecord := by
  intro n p q
  refine ⟨?_, fun _ _ => rfl, ?_⟩
  · rw [AxisArray.composeLoop_eq_compose, AxisArray.ofPermutation_comp]
  · intro s α x
    exact (nested s (permuteAxes p s) (permuteAxes q (permuteAxes p s)) p q
      (fun i => congrArg s (p.output_input i))
      (fun i => congrArg (permuteAxes p s) (q.output_input i))).2 α x

example : IdentityRecord := identityRecord
example : ComposeRecord := composeRecord
#print axioms identityRecord
#print axioms composeRecord
end RevisedBenchmark.TransposeRecords
