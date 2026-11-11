module

public import TensorRewrite.Theory.ConvolutionDotLemmas

/-! Ordered convolution values with explicit scalar operations and precision stages.
Invalid samples contribute the supplied accumulator value. No algebraic law is assumed. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.ConvolutionOrdered

open Pilot Convolution

/-- One scheduled contribution. Input/kernel types and product/accumulator type may differ. -/
def term {rank : Nat} {L R Acc : Type} (plan : Plan rank) (padding : Acc)
    (multiply : L → R → Acc) (input : Input plan L) (kernel : Kernel plan R)
    (output : OutputIndex plan)
    (position :
      Fin (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)) : Acc :=
  let channel := FiniteProduct.row position
  let spatial := LinearIndex.delinearize plan.kernelShape (FiniteProduct.column position)
  match spatialInput? plan output.spatial spatial with
  | none => padding
  | some coordinates =>
    multiply (input (FiniteProduct.join output.batchGroup output.batch)
      (FiniteProduct.join output.featureGroup channel) coordinates)
      (kernel output.batchGroup output.featureGroup output.feature channel spatial)

/-- Contributions are ordered by channel, then dim0-major spatial kernel position. -/
def terms {rank : Nat} {L R Acc : Type} (plan : Plan rank) (padding : Acc)
    (multiply : L → R → Acc) (input : Input plan L) (kernel : Kernel plan R)
    (output : OutputIndex plan) : List Acc :=
  (List.finRange (plan.inputFeaturesPerGroup * LinearIndex.elementCount plan.kernelShape)).map
    (term plan padding multiply input kernel output)

/-- Fold in the stated order from the explicit initializer, then perform the output conversion. -/
def convolve {rank : Nat} {L R Acc Result : Type} (plan : Plan rank)
    (add : Acc → Acc → Acc) (initial padding : Acc) (multiply : L → R → Acc)
    (finish : Acc → Result) (input : Input plan L) (kernel : Kernel plan R) :
    OutputIndex plan → Result :=
  fun output => finish ((terms plan padding multiply input kernel output).foldl add initial)

end TensorRewrite.Theory.ConvolutionOrdered
