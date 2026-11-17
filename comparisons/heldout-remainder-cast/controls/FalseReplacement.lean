module
import Spec
open TensorRewrite.Pilot Heldout.RemainderCast
set_option autoImplicit false
namespace Heldout.RemainderCast.Tests

def shape : Shape 1 := fun _ => 2
def left : Tensor shape (BitVec 8) := fun i => if (i 0).val = 0 then 251 else 7
def right : Tensor shape (BitVec 8) := fun i => if (i 0).val = 0 then 10 else 0
def at0 : Index shape := fun _ => ⟨0, by simp [shape]⟩
def at1 : Index shape := fun _ => ⟨1, by simp [shape]⟩
/-- Nonempty and divisor-zero examples exercise actual BitVec graph definitions. -/
example : (original 16 left right at0).toNat = 1 := by decide
example : (replacement left right at0).toNat = 1 := by decide
example : (original 16 left right at1).toNat = 7 := by decide
example : (replacement left right at1).toNat = 7 := by decide
/-- A well-typed replacement with an incremented divisor is not equivalent. -/
def wrong : Tensor shape (BitVec 8) := Tensor.map₂ (fun a b => a % (b + 1)) left right
example : (wrong at0).toNat = 9 := by decide
example : original 16 left right at0 ≠ wrong at0 := by decide
/-- Reversing the widening inequality can break the equation. -/
def narrowLeft : Tensor shape (BitVec 8) := fun _ => 200
def narrowRight : Tensor shape (BitVec 8) := fun _ => 13
example : (original 4 narrowLeft narrowRight at0).toNat = 8 := by decide
example : (replacement narrowLeft narrowRight at0).toNat = 5 := by decide
example : original 4 narrowLeft narrowRight at0 ≠ replacement narrowLeft narrowRight at0 := by decide

/-- An axis of extent zero admits no tensor coordinate. -/
example : ¬ Nonempty (Index (fun _ : Fin 1 => 0)) := by
  intro ⟨index⟩
  exact Fin.elim0 (index 0)
/-- Width zero is included by the mathematical proposition. -/
example : (0 : BitVec 0) % 0 = 0 := by decide
/-- The well-typed incremented-divisor graph must fail at this concrete witness. -/
example : original 16 left right at0 = wrong at0 := by decide
end Heldout.RemainderCast.Tests
