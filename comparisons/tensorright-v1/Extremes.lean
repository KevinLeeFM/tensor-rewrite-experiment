module

public import TensorRewrite.Pilot.Tensor
public import Mathlib.Order.WithBotTop

/-! Paper-era Min/Max identities with explicit extended-order constants. -/

public section

set_option autoImplicit false

namespace TensorRewrite.PaperComparison.Extremes

open Pilot

/-- `max/rule01`: a finite tensor value is unchanged by maximum with negative infinity. -/
theorem max_negative_infinity {α : Type} [LinearOrder α] {rank : Nat} {shape : Shape rank}
    (input : Tensor shape α) :
    Tensor.map₂ max (Tensor.map (fun (x : α) => (x : WithBot α)) input) (Tensor.constant ⊥) =
      Tensor.map (fun (x : α) => (x : WithBot α)) input := by
  funext index
  exact max_eq_left bot_le

/-- `max/rule02`: a finite tensor value is unchanged by minimum with positive infinity. -/
theorem min_positive_infinity {α : Type} [LinearOrder α] {rank : Nat} {shape : Shape rank}
    (input : Tensor shape α) :
    Tensor.map₂ min (Tensor.map (fun (x : α) => (x : WithTop α)) input) (Tensor.constant ⊤) =
      Tensor.map (fun (x : α) => (x : WithTop α)) input := by
  funext index
  exact min_eq_left le_top

#print axioms max_negative_infinity
#print axioms min_positive_infinity

end TensorRewrite.PaperComparison.Extremes
