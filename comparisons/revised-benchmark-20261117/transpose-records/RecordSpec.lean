import TransSpec
set_option autoImplicit false

namespace RevisedBenchmark.TransposeRecords
open TensorRewrite.Pilot Tensor

/-- Axis attributes may contain a static size, a dynamic bound, an unbounded
marker, a runtime size, or any joint descriptor. -/
def permuteAxes {n : Nat} {A : Type} (p : AxisPermutation n) (a : Fin n → A) :
    Fin n → A := fun j => a (p.outputToInput j)

/-- Transpose realization at the shape computed from its input. -/
def act {n : Nat} (s : Shape n) (p : AxisPermutation n) {α : Type}
    (x : Tensor s α) : Tensor (permuteAxes p s) α :=
  transpose p (fun i => congrArg s (p.output_input i)) x

/-- Every sorted legal permutation preserves all per-axis attributes,
the realized shape, and every value. -/
def IdentityRecord : Prop := ∀ {n : Nat} (p : AxisPermutation n)
    (_sorted : ∀ i j, i < j → p.outputToInput i ≤ p.outputToInput j),
    (∀ (A : Type) (a : Fin n → A), permuteAxes p a = a) ∧
    ∀ (s : Shape n), ∃ same : permuteAxes p s = s,
      ∀ (α : Type) (x : Tensor s α), act s p x = same.symm ▸ x

/-- The emitted vector is a permutation. It computes the complete intermediate
and final logical descriptor transformation and preserves every realized tensor. -/
def ComposeRecord : Prop := ∀ {n : Nat} (p q : AxisPermutation n),
    AxisArray.composeLoop (AxisArray.ofPermutation p) (AxisArray.ofPermutation q) =
      (AxisArray.ofPermutation (p.comp q)).toArray ∧
    (∀ (A : Type) (a : Fin n → A), permuteAxes q (permuteAxes p a) =
      permuteAxes (p.comp q) a) ∧
    ∀ (s : Shape n) (α : Type) (x : Tensor s α),
      act (permuteAxes p s) q (act s p x) = act s (p.comp q) x

end RevisedBenchmark.TransposeRecords
