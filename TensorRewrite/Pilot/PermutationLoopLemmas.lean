import TensorRewrite.Pilot.PermutationLoop
import TensorRewrite.Pilot.PermutationArrayLemmas

namespace TensorRewrite.Pilot.AxisArray

variable {rank : Nat} (left right : AxisArray rank)

/-- Each iteration appends precisely one result. -/
theorem composePrefix_size (count : Nat) (bound : count ≤ rank) :
    (composePrefix left right count bound).size = count := by
  induction count with
  | zero => rfl
  | succ count ih => simp only [composePrefix, Array.size_push, ih]

/-- Every coordinate in the constructed prefix has the source-specified value. -/
theorem composePrefix_get (count : Nat) (bound : count ≤ rank) (i : Nat) (hi : i < count) :
    (composePrefix left right count bound)[i]'(by rw [composePrefix_size]; exact hi) =
      left[right[(⟨i, by omega⟩ : Fin rank)]] := by
  induction count with
  | zero => omega
  | succ count ih =>
    by_cases earlier : i < count
    · simp only [composePrefix, Array.getElem_push]
      simp only [composePrefix_size, earlier, ↓reduceDIte]
      exact ih (by omega) earlier
    · have last : i = count := by omega
      subst i
      simp only [composePrefix, Array.getElem_push]
      simp only [composePrefix_size, Nat.lt_irrefl, ↓reduceDIte]

/-- The complete append loop equals the array composition specification. -/
theorem composeLoop_eq_compose (left right : AxisArray rank) :
    composeLoop left right = (compose left right).toArray := by
  apply Array.ext
  · simp only [composeLoop, composePrefix_size, Vector.size_toArray]
  · intro i hi₁ hi₂
    have hi : i < rank := by simpa only [composeLoop, composePrefix_size] using hi₁
    rw [show (composeLoop left right)[i] = left[right[(⟨i, hi⟩ : Fin rank)]] from
      composePrefix_get left right rank (Nat.le_refl rank) i hi]
    simp only [Vector.getElem_toArray, compose, Vector.getElem_map, Fin.getElem_fin]

end TensorRewrite.Pilot.AxisArray
