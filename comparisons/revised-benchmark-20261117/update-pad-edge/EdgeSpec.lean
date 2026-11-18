import TensorRewrite.Pilot.DynamicIndexValue
set_option autoImplicit false
namespace RevisedBenchmark.EdgeUpdate
open TensorRewrite.Pilot.DynamicIndex
/-- The list orders positions on the only padded axis; each entry has all other coordinates. -/
abbrev Axis (C A : Type) := List (C → A)
def base {C A : Type} (high : Bool) (x : Axis C A) (w : Nat) (fill : A) :=
  let p := List.replicate w (fun (_ : C) => fill)
  if high then x ++ p else p ++ x
def update {C A : Type} (x y : Axis C A) (start : Int) : Axis C A :=
  let k := (clampStart x.length y.length start).toNat
  x.take k ++ y ++ x.drop (k+y.length)
def Case : Prop := ∀ (C A : Type) (x y : Axis C A) (_ : x ≠ []) (_ : y ≠ [])
    (fill : A) (start : Int) (high : Bool)
    (_ : clampStart (x.length+y.length) y.length start = (if high then (x.length : Int) else 0)),
    update (base high x y.length fill) y start = if high then x ++ y else y ++ x
end RevisedBenchmark.EdgeUpdate
