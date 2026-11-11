module

public import TensorRewrite.Theory.ShapeTransport

/-! Equal-shape transport preserves coordinates and composes as ordinary typed equality. -/

public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ShapeTransport

open Pilot

/-- A shape transport never changes any coordinate's natural-number value. -/
theorem indexAlong_value {rank : Nat} {inputShape outputShape : Shape rank}
    (same : inputShape = outputShape) (index : Index outputShape) (axis : Fin rank) :
    (indexAlong same index axis).val = (index axis).val := rfl

/-- Transport along a reflexive complete-shape equality is the identity coordinate map. -/
theorem indexAlong_refl {rank : Nat} {shape : Shape rank} (index : Index shape) :
    indexAlong rfl index = index := rfl

/-- Reflexive complete-shape transport retains the original tensor. -/
theorem tensorAlong_refl {rank : Nat} {shape : Shape rank} {α : Type}
    (input : Tensor shape α) : tensorAlong rfl input = input := rfl

/-- Two complete-shape transports compose without changing a data value or coordinate. -/
theorem tensorAlong_trans {rank : Nat} {first middle last : Shape rank} {α : Type}
    (firstSame : first = middle) (secondSame : middle = last) (input : Tensor first α) :
    tensorAlong secondSame (tensorAlong firstSame input) =
      tensorAlong (firstSame.trans secondSame) input := by
  funext index
  apply congrArg input
  funext axis
  apply Fin.ext
  rfl

end TensorRewrite.Theory.ShapeTransport
