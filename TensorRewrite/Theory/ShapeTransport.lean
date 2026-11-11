module

public import TensorRewrite.Pilot.Tensor

/-! Coordinate-preserving transport across a proved equality of complete tensor shapes. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ShapeTransport

open Pilot

/-- Read the same coordinate through the input side of an actual shape equality. -/
def indexAlong {rank : Nat} {inputShape outputShape : Shape rank}
    (same : inputShape = outputShape) (index : Index outputShape) : Index inputShape :=
  fun axis => Fin.cast (congrFun same axis).symm (index axis)

/-- Preserve every logical data value while changing only the equal shape's type expression. -/
def tensorAlong {rank : Nat} {inputShape outputShape : Shape rank} {α : Type}
    (same : inputShape = outputShape) (input : Tensor inputShape α) : Tensor outputShape α :=
  fun index => input (indexAlong same index)

end TensorRewrite.Theory.ShapeTransport
