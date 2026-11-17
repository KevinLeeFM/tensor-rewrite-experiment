module
public import Spec
@[expose] public section
open TensorRewrite.Pilot Heldout.TransposeBroadcast
set_option autoImplicit false
namespace Heldout.TransposeBroadcast

theorem proof : Goal := by
  intro small rank inputShape middle perm axes conditions α input
  funext out
  rfl

#print axioms proof
end Heldout.TransposeBroadcast
