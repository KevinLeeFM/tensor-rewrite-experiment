module

public import Std

/-! Pilot value semantics. Shapes have arbitrary finite rank and natural extents.
This module does not model HLO graph metadata, control dependencies or layout. -/

@[expose] public section

namespace TensorRewrite.Pilot

/-- Arbitrary finite-rank extents, including zero extents. -/
abbrev Shape (rank : Nat) := Fin rank → Nat

/-- A bounded coordinate on every axis of the shape. -/
abbrev Index {rank : Nat} (shape : Shape rank) := (axis : Fin rank) → Fin (shape axis)

/-- A tensor's logical value at every valid coordinate. -/
abbrev Tensor {rank : Nat} (shape : Shape rank) (α : Type) := Index shape → α

namespace Tensor

variable {rank : Nat} {shape : Shape rank} {α β γ : Type}

/-- A uniform tensor, including scalar and empty-shape cases. -/
def constant (value : α) : Tensor shape α := fun _ => value

/-- Elementwise unary operation with unchanged shape. -/
def map (f : α → β) (input : Tensor shape α) : Tensor shape β := fun i => f (input i)

/-- Elementwise binary operation on identically shaped inputs. -/
def map₂ (f : α → β → γ) (lhs : Tensor shape α) (rhs : Tensor shape β) :
    Tensor shape γ := fun i => f (lhs i) (rhs i)

end Tensor
end TensorRewrite.Pilot
