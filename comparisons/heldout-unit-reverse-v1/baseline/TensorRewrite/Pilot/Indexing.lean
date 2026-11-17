module

public import TensorRewrite.Pilot.Tensor

@[expose] public section

namespace TensorRewrite.Pilot

namespace Tensor

variable {rank : Nat} {shape : Shape rank} {α : Type}

/-- Pull back tensor values along a map from output indices to input indices. -/
def reindex {outputRank : Nat} {outputShape : Shape outputRank}
    (indexMap : Index outputShape → Index shape) (x : Tensor shape α) :
    Tensor outputShape α := fun i => x (indexMap i)

/-- Reverse each selected axis within its extent. -/
def reverseIndex (axes : Fin rank → Bool) (i : Index shape) : Index shape :=
  fun axis => if axes axis then (i axis).rev else i axis

/-- Logical axis reversal; layout and graph metadata are outside this model. -/
def reverse (axes : Fin rank → Bool) (x : Tensor shape α) : Tensor shape α :=
  reindex (reverseIndex axes) x

/-- Interpret a list of legal axes as a membership mask. -/
def axisMask (axes : List (Fin rank)) : Fin rank → Bool :=
  fun axis => decide (axis ∈ axes)

end Tensor
end TensorRewrite.Pilot
