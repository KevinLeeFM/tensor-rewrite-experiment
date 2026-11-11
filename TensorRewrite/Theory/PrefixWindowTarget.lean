module

public import TensorRewrite.Theory.PrefixWindowStride

/-! Direct prefix semantics and derived coordinates, independent of window evaluation. -/

@[expose] public section

set_option autoImplicit false

namespace TensorRewrite.Theory.PrefixWindow

open Pilot

/-- Map the scan axis directly and retained axes through their proved stride coordinates. -/
def outputIndex : {rank : Nat} → (plan : Plan rank) →
    Index (windowPlan plan).outputShape → Index (windowPlan plan).inputShape
  | _, .scan extent tail stride, output =>
    Fin.cases (Fin.cast (prefix_output_extent extent) (output ⟨0, Nat.zero_lt_succ _⟩))
      (fun axis => retainedIndex (tail axis) (stride axis) (output axis.succ))
  | _, .keep extent stride tail, output =>
    Fin.cases (retainedIndex extent stride (output ⟨0, Nat.zero_lt_succ _⟩))
      (outputIndex tail (fun axis => output axis.succ))

/-- Number of leading invalid kernel positions at this output. -/
def paddingCount {rank : Nat} (plan : Plan rank) (output : Index (windowPlan plan).outputShape) :
    Nat := scanExtent plan - 1 - (coordinate plan (outputIndex plan output)).val

/-- Inclusive prefix values from original coordinates, independent of window sampling. -/
def prefixValues {rank : Nat} {α : Type} (plan : Plan rank)
    (input : Tensor (windowPlan plan).inputShape α) (output : Index (windowPlan plan).outputShape) :
    List α :=
  (List.finRange ((coordinate plan (outputIndex plan output)).val + 1)).map fun position =>
    input (replaceCoordinate plan (outputIndex plan output) ⟨position.val, by
      have bound := (coordinate plan (outputIndex plan output)).isLt
      have indexBound := position.isLt
      omega⟩)

end TensorRewrite.Theory.PrefixWindow
