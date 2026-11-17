module
public import TensorRewrite.Pilot.Tensor
/-! Unsigned remainder through a value-preserving width extension and truncation.
The source translation and native evaluator/back-end correspondence are not proved. -/
@[expose] public section
set_option autoImplicit false
namespace Heldout.RemainderCast
open TensorRewrite.Pilot

/-- The actual pointwise widened, remainder, narrowed graph. -/
def original {rank narrow : Nat} {shape : Shape rank} (wide : Nat)
    (left right : Tensor shape (BitVec narrow)) : Tensor shape (BitVec narrow) :=
  Tensor.map₂ (fun a b => ((a.setWidth wide) % (b.setWidth wide)).setWidth narrow) left right

/-- The pointwise narrow unsigned remainder graph. -/
def replacement {rank narrow : Nat} {shape : Shape rank}
    (left right : Tensor shape (BitVec narrow)) : Tensor shape (BitVec narrow) :=
  Tensor.map₂ (fun a b => a % b) left right

/-- Arbitrary-rank unsigned value equality, including zero divisor and empty domains. -/
def Goal : Prop :=
  ∀ (rank narrow wide : Nat) (shape : Shape rank), narrow ≤ wide →
    ∀ (left right : Tensor shape (BitVec narrow)), original wide left right = replacement left right

#print Goal
#print axioms Goal
end Heldout.RemainderCast
