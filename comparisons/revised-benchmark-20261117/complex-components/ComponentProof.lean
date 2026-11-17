import ComponentSpec
set_option autoImplicit false
namespace RevisedBenchmark.Components
open TensorRewrite.Pilot Tensor

theorem reconstruction : Reconstruction := by
  intro r s R z x
  funext i
  exact Prod.eta (x i)

theorem realProjection : RealProjection := by intro r s R a b; rfl
theorem imagProjection : ImagProjection := by intro r s R z a b; rfl
theorem realOfReal : RealOfReal := by intro r s R x; rfl
theorem imagOfReal : ImagOfReal := by intro r s R z x; rfl
theorem reconstructionTypeBoundary : ReconstructionTypeBoundary :=
  fun _ => ⟨Eq.symm, Eq.symm⟩

example : Reconstruction := reconstruction
example : RealProjection := realProjection
example : ImagProjection := imagProjection
example : RealOfReal := realOfReal
example : ImagOfReal := imagOfReal
#print axioms reconstruction
#print axioms realProjection
#print axioms imagProjection
#print axioms realOfReal
#print axioms imagOfReal
#print axioms reconstructionTypeBoundary
end RevisedBenchmark.Components
