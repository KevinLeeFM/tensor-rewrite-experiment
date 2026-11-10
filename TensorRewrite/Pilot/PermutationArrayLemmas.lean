module

public import TensorRewrite.Pilot.PermutationArrays

public section

namespace TensorRewrite.Pilot.AxisArray

variable {rank : Nat}

/-- Decoding preserves each signed source coordinate, without truncation. -/
theorem decode_preserves (raw : Vector Int rank)
    (valid : ∀ i : Fin rank, 0 ≤ raw[i] ∧ raw[i] < (rank : Int)) (i : Fin rank) :
    (((decode raw valid)[i]).val : Int) = raw[i] := by
  simp only [Fin.getElem_fin, decode, Vector.getElem_ofFn]
  exact Int.toNat_of_nonneg (valid i).1

/-- Elementwise specification of the source composition loop. -/
theorem compose_get (left right : AxisArray rank) (i : Fin rank) :
    (compose left right)[i] = left[right[i]] := by
  simp only [Fin.getElem_fin, compose, Vector.getElem_map]

/-- Tabulation agrees with a permutation's coordinate map. -/
theorem ofPermutation_get (p : AxisPermutation rank) (i : Fin rank) :
    (ofPermutation p)[i] = p.outputToInput i := by
  simp only [Fin.getElem_fin, ofPermutation, Vector.getElem_ofFn]

/-- The model's composition order is exactly the source array convention. -/
theorem ofPermutation_comp (p q : AxisPermutation rank) :
    ofPermutation (p.comp q) = compose (ofPermutation p) (ofPermutation q) := by
  apply Vector.ext
  intro i hi
  simp only [Fin.getElem_fin, ofPermutation, compose, Vector.getElem_ofFn, Vector.getElem_map,
    AxisPermutation.comp]

end TensorRewrite.Pilot.AxisArray
