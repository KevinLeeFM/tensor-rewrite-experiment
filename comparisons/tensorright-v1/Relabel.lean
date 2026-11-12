module

public import TensorRewrite.Pilot.Permutation

/-! Paper-era axis relabeling, expressed as lawful bounded axis bijections. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Relabel

open Pilot

/-- `relabel/rule01`: two actual axis relabelings equal the composed relabeling. -/
theorem compose {α : Type} {rank : Nat} {a b c : Shape rank}
    (p q : AxisPermutation rank)
    (hp : ∀ axis, b (p.inputToOutput axis) = a axis)
    (hq : ∀ axis, c (q.inputToOutput axis) = b axis) (input : Tensor a α) :
    Tensor.transpose q hq (Tensor.transpose p hp input) =
      Tensor.transpose (p.comp q)
        (fun axis => (hq (p.inputToOutput axis)).trans (hp axis)) input := by
  funext index
  apply congrArg input
  funext axis
  apply Fin.ext
  rfl

/-- `relabel/rule02`: identity relabeling leaves the tensor unchanged. -/
theorem identity {α : Type} {rank : Nat} {shape : Shape rank} (input : Tensor shape α) :
    Tensor.transpose (AxisPermutation.identity rank) (fun _ => rfl) input = input := rfl

/-- `broadcast/rule03`: relabeling preserves a uniform tensor on the renamed shape. -/
theorem uniform {α : Type} {rank : Nat} {a b : Shape rank} (p : AxisPermutation rank)
    (extents : ∀ axis, b (p.inputToOutput axis) = a axis) (value : α) :
    Tensor.transpose p extents (Tensor.constant value) = Tensor.constant value := rfl

#print axioms compose
#print axioms identity
#print axioms uniform

end TensorRewrite.PaperComparison.Relabel
