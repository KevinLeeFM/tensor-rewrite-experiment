module

public import TensorRewrite.Pilot.FiniteProduct
public import TensorRewrite.Pilot.Tensor

/-! Logical dim0-major linear positions, independent of physical buffer layout. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Pilot.LinearIndex

/-- Number of elements in an arbitrary-rank shape; a scalar has one element. -/
def elementCount : {rank : Nat} → Shape rank → Nat
  | 0, _ => 1
  | _ + 1, shape => shape 0 * elementCount (fun axis => shape axis.succ)

/-- Pack bounded tensor coordinates in increasing dimension order, last axis fastest. -/
def linearize : {rank : Nat} → (shape : Shape rank) → Index shape → Fin (elementCount shape)
  | 0, _, _ => ⟨0, Nat.zero_lt_one⟩
  | _ + 1, shape, index =>
    FiniteProduct.join (index 0)
      (linearize (fun axis => shape axis.succ) (fun axis => index axis.succ))

/-- Recover every bounded coordinate from a valid logical linear position. -/
def delinearize : {rank : Nat} → (shape : Shape rank) → Fin (elementCount shape) → Index shape
  | 0, _, _ => fun axis => Fin.elim0 axis
  | _ + 1, shape, position =>
    Fin.cases (FiniteProduct.row position)
      (delinearize (fun axis => shape axis.succ) (FiniteProduct.column position))

end TensorRewrite.Pilot.LinearIndex
