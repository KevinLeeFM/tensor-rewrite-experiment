module
public import HistoricalShift
public section
set_option autoImplicit false
namespace RevisedBenchmark.NegativePad
open TensorRewrite.Pilot TensorRewrite.PaperComparison.SignedPad
private theorem middleExact {r : Nat} {s o : Shape r} (p : Params s o) (d : Fin r) :
    (middle p d : Int) = extent (s d) (max 0 (p.low d)) (max 0 (p.high d)) (p.interior d) := by
  unfold middle
  apply Int.toNat_of_nonneg
  have original := p.shape d
  unfold extent at *
  omega

/-- All attribute and slice validity witnesses are constructed from the original Pad. -/
theorem correct : Goal := by
  intro r s o p
  let mid : Params s (middle p) :=
    ⟨fun d => max 0 (p.low d), fun d => max 0 (p.high d), p.interior, middleExact p⟩
  refine ⟨mid, rfl, rfl, rfl, ?_⟩
  have valid (d : Fin r) : SliceShape.IsWellFormed (middle p d) (o d) (crop p d) := by
    have a := p.shape d
    have b := middleExact p d
    unfold extent at a b
    simp [crop, SliceShape.IsWellFormed, SliceShape.Axis.elementCount]
    omega
  refine ⟨valid, ?_⟩
  intro α fill input
  apply pad_shift p mid (crop p) valid
  · intro d
    change max 0 (-p.low d) = max 0 (p.low d) - p.low d
    omega
  · intro d; rfl
  · intro d; rfl
#print axioms correct
end RevisedBenchmark.NegativePad
