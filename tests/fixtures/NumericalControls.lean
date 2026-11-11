import TensorRewrite.Theory.NumericalCounterexamples
import TensorRewrite.Pilot.LinearIndexLemmas
import Mathlib.Algebra.Field.Rat

open TensorRewrite.Pilot TensorRewrite.Theory.Numerical

/-- Stable exact rational observations, independent of decimal/host floating point. -/
def numericalRat (x : ℚ) : String := s!"{x.num}/{x.den}"

/-- Explicit retained field expression pairs at scalar tensor shape. -/
def numericalFieldRows : IO Unit := do
  let mut sample := 0
  for a in [-2,-1,0,1,2] do
    for b in [-2,-1,0,1,2] do
      for c in [-2,-1,0,1,2] do
        for d in [-2,-1,0,1,2] do
          let x : ℚ := a
          let y : ℚ := b
          let z : ℚ := c
          let t : ℚ := d
          let left := [x / 1, x / (1 / y), (x / y) / (z / t), (x / y) / z,
            x / (y / z), x / y, x / y, 0 / y, 1 / y]
          let right := [x, x * y, (x * t) / (y * z), x / (y * z), (x * z) / y,
            x * (1 / y), x * (1 / y), (1 / y) * 0, (1 / y) * 1]
          IO.println s!"NUM_FIELD sample={sample} input={a},{b},{c},{d} lhs={String.intercalate "," (left.map numericalRat)} rhs={String.intercalate "," (right.map numericalRat)}"
          sample := sample + 1

/-- Actual bounded Broadcast graphs at scalar, empty, retained and permuted axes. -/
def numericalGraph {smallRank rank : Nat} {smallShape : Shape smallRank} {shape : Shape rank}
    (scenario : Nat) (axes : IndexMaps.BroadcastAxes smallRank rank)
    (extents : ∀ axis, smallShape axis = shape (axes.decode axis)) : IO Unit := do
  let input : Tensor shape ℚ := fun i => (LinearIndex.linearize shape i).val - 2
  let small : Tensor smallShape ℚ := fun i => (LinearIndex.linearize smallShape i).val - 1
  let broadcast := Tensor.reindex (IndexMaps.broadcastIndex axes extents)
  IO.println s!"NUM_GRAPH_COUNT scenario={scenario} small={(Vector.ofFn smallShape).toList} output={(Vector.ofFn shape).toList} axes={axes.values.toList}"
  for position in List.finRange (LinearIndex.elementCount shape) do
    let index := LinearIndex.delinearize shape position
    let left := Tensor.map₂ (· / ·) input (broadcast small)
    let right := Tensor.map₂ (· * ·) input (broadcast (Tensor.map (1 / ·) small))
    IO.println s!"NUM_GRAPH scenario={scenario} output={position.val} rule=divide lhs={numericalRat (left index)} rhs={numericalRat (right index)}"
    for p in [false,true] do
      let predicate : Tensor shape ℚ := Tensor.constant (if p then 1 else 0)
      let left := Tensor.map₂ (· / ·) predicate (broadcast small)
      let right := Tensor.map₂ (· * ·) (broadcast (Tensor.map (1 / ·) small)) predicate
      IO.println s!"NUM_GRAPH scenario={scenario} output={position.val} rule=predicate{p} lhs={numericalRat (left index)} rhs={numericalRat (right index)}"

#eval show IO Unit from do
  numericalFieldRows
  numericalGraph (smallShape := fun _ : Fin 1 => 2)
    (shape := Fin.cases 3 (fun _ : Fin 1 => 2)) 0 ⟨#v[1], by decide⟩ (by decide)
  numericalGraph (smallShape := fun _ : Fin 1 => 2)
    (shape := Fin.cases 0 (fun _ : Fin 1 => 2)) 1 ⟨#v[1], by decide⟩ (by decide)
  numericalGraph (smallShape := (Fin.elim0 : Shape 0))
    (shape := fun _ : Fin 2 => 2) 2 ⟨#v[], fun a => Fin.elim0 a⟩ (fun a => Fin.elim0 a)
  numericalGraph (smallShape := Fin.cases 2 (fun _ : Fin 1 => 3))
    (shape := Fin.cases 3 (fun _ : Fin 1 => 2)) 3 ⟨#v[1,0], by decide⟩ (by decide)
  numericalGraph (smallShape := fun _ : Fin 1 => 0)
    (shape := Fin.cases 0 (fun _ : Fin 1 => 3)) 4 ⟨#v[0], by decide⟩ (by decide)

namespace NumericalControls

/-- Zero remains an admitted base for exponent zero. -/
theorem zero_power_zero : (0 : ℝ) ^ (0 : ℝ) = 1 := by norm_num
/-- Negative bases remain admitted at the cubic exponent. -/
theorem negative_cube : (-2 : ℝ) ^ (3 : ℝ) = -8 := by norm_num
/-- Real power one half and sqrt share the same negative-base totalization. -/
theorem negative_half : (-4 : ℝ) ^ (1 / 2 : ℝ) = 0 := by
  rw [← Real.sqrt_eq_rpow]
  exact Real.sqrt_eq_zero_of_nonpos (by norm_num)
/-- The real inverse-square graph returns a positive magnitude at a negative input. -/
theorem negative_inverse_square : (Real.sqrt ((-3 : ℝ) ^ (-2 : ℝ)))⁻¹ = 3 := by
  rw [Real.rpow_neg_ofNat, zpow_neg, zpow_ofNat, Real.sqrt_inv,
    Real.sqrt_sq_eq_abs, inv_inv]
  norm_num
/-- The reciprocal identity remains valid at a zero denominator in exact fields. -/
theorem quotient_zero : ((3 : ℚ) / 0) / (2 / 0) = 0 := by norm_num
/-- The negative real axis is a branch endpoint for principal complex sqrt. -/
theorem principal_negative_root : Complex.sqrt (-1) = Complex.I := Complex.sqrt_neg_one
/-- A negative real square has positive real principal root. -/
theorem principal_square_real : Complex.sqrt ((-2 : ℂ) * (-2)) = 2 := by
  simpa using TensorRewrite.Theory.ScalarDomains.complex_sqrt_square_ofReal (-2)
/-- The positive principal-log strip endpoint is included. -/
theorem log_upper_endpoint : Complex.log (Complex.exp (Real.pi * Complex.I)) =
    Real.pi * Complex.I := by
  apply Complex.log_exp <;> simp [Real.pi_pos]
/-- The negative strip endpoint gives the opposite branch. -/
theorem log_lower_endpoint : Complex.log (Complex.exp (-Real.pi * Complex.I)) ≠
    -Real.pi * Complex.I := by
  intro equal
  have lower := Complex.neg_pi_lt_arg (Complex.exp (-Real.pi * Complex.I))
  rw [← Complex.log_im, equal] at lower
  simp at lower
/-- The empty tensor domain admits equality without adding a nonempty premise. -/
theorem empty_sqrt_square :
    (fun i : Index (fun _ : Fin 1 => 0) => Real.sqrt (Fin.elim0 (i 0)) ^ 2) =
      (fun i => Fin.elim0 (i 0)) := by
  funext i
  exact Fin.elim0 (i 0)

end NumericalControls

#print axioms NumericalControls.zero_power_zero
#print axioms NumericalControls.negative_cube
#print axioms NumericalControls.negative_half
#print axioms NumericalControls.negative_inverse_square
#print axioms NumericalControls.quotient_zero
#print axioms NumericalControls.principal_negative_root
#print axioms NumericalControls.principal_square_real
#print axioms NumericalControls.log_upper_endpoint
#print axioms NumericalControls.log_lower_endpoint
#print axioms NumericalControls.empty_sqrt_square
