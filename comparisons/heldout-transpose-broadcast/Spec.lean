module
public import TensorRewrite.Pilot.Permutation
/-! Statement only: logical transpose of a broadcast, under source-style axis guards. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.TransposeBroadcast
open TensorRewrite.Pilot

/-- The output shape of the actual permutation. -/
def outputShape {rank : Nat} (middle : Shape rank) (perm : AxisPermutation rank) : Shape rank :=
  fun i => middle (perm.outputToInput i)

/-- Axis order is the source's sorted dimension-array condition, expressed for bounded axes. -/
def ordered {small rank : Nat} (axes : Fin small → Fin rank) : Prop :=
  ∀ i j, i.val < j.val → (axes i).val < (axes j).val

/-- The inverse permutation computes the replacement broadcast axes. -/
def movedAxes {small rank : Nat} (perm : AxisPermutation rank) (axes : Fin small → Fin rank) :
    Fin small → Fin rank := fun i => perm.inputToOutput (axes i)

/-- Exact model assumptions: legal mapped extents and both sorted source dimension arrays. -/
structure Conditions {small rank : Nat} (inputShape : Shape small) (middle : Shape rank)
    (perm : AxisPermutation rank) (axes : Fin small → Fin rank) : Prop where
  extents : ∀ i, inputShape i = middle (axes i)
  originalOrdered : ordered axes
  replacementOrdered : ordered (movedAxes perm axes)

/-- Actual original Broadcast: project onto its operand axes. -/
def broadcast {small rank : Nat} {inputShape : Shape small} {middle : Shape rank} {α : Type}
    (axes : Fin small → Fin rank) (extents : ∀ i, inputShape i = middle (axes i))
    (input : Tensor inputShape α) : Tensor middle α :=
  fun out => input (fun i => Fin.cast (extents i).symm (out (axes i)))

/-- Both independently defined actual graph terms and their equality, with no proof supplied. -/
def Goal : Prop :=
  ∀ (small rank : Nat) (inputShape : Shape small) (middle : Shape rank)
    (perm : AxisPermutation rank) (axes : Fin small → Fin rank)
    (conditions : Conditions inputShape middle perm axes) (α : Type) (input : Tensor inputShape α),
    Tensor.transpose perm (fun i => by simp [outputShape, perm.output_input])
      (broadcast axes conditions.extents input) =
    @broadcast small rank inputShape (outputShape middle perm) α (movedAxes perm axes)
      (fun i => (conditions.extents i).trans (congrArg middle (perm.output_input (axes i))).symm)
      input

#print Goal
#print axioms Goal
end Heldout.TransposeBroadcast
