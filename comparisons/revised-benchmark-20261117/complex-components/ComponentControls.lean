import ComponentProof
set_option autoImplicit false
namespace RevisedBenchmark.Components
open TensorRewrite.Pilot Tensor
private def s : Shape 1 := fun _ => 2
private def pairTensor : Tensor s (Int × Int) :=
  fun i => if (i 0).val = 0 then (3, -7) else (11, 5)
private def i0 : Index s := fun _ => (0 : Fin 2)
private def i1 : Index s := fun _ => (1 : Fin 2)
example : map (realPart .complex) pairTensor i0 = 3 := rfl
example : map (imagPart (0 : Int) .complex) pairTensor i0 = -7 := rfl
example : pairTensor i0 ≠ pairTensor i1 := by decide
example : makeComplex (map (imagPart (0 : Int) .complex) pairTensor)
    (map (realPart .complex) pairTensor) i0 ≠ pairTensor i0 := by decide
example : makeComplex (map (realPart .complex) pairTensor)
    (map (imagPart (0 : Int) .complex) (constant (8, 5))) i0 ≠ pairTensor i0 := by decide

private def Original (x : Int) : Sigma (Value Int) :=
  ⟨.complex, (realPart .real x, imagPart 0 .real x)⟩
private def Forwarded (x : Int) : Sigma (Value Int) := ⟨.real, x⟩
example : Original 3 ≠ Forwarded 3 := by
  intro same
  have tags := congrArg Sigma.fst same
  cases tags
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  rintro ⟨i⟩
  exact Fin.elim0 (i 0)
example : Nonempty (Index (fun _ : Fin 0 => 0)) := ⟨fun i => Fin.elim0 i⟩
end RevisedBenchmark.Components
