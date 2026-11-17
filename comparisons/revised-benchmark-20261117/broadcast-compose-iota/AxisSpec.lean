import PaperIota
set_option autoImplicit false
namespace RevisedBenchmark.BroadcastAxis
open TensorRewrite.Pilot TensorRewrite.PaperComparison.Iota

def Ordered {r q : Nat} (a : IndexMaps.BroadcastAxes r q) : Prop :=
  ∀ i j, i < j → a.decode i < a.decode j

def Composed {r m q : Nat} (a : IndexMaps.BroadcastAxes r m) (b : IndexMaps.BroadcastAxes m q) :
    Prop := Ordered a → Ordered b → Ordered (composeAxes a b)

def EncodedIota : Prop := ∀ {r q : Nat} (s : Shape r) (t : Shape q)
    (a : IndexMaps.BroadcastAxes r q) (h : ∀ k, s k = t (a.decode k))
    (k : Fin r) (α : Type) (encode : Nat → α),
    Tensor.reindex (IndexMaps.broadcastIndex a h) (fun j => encode (j k).val) =
      fun j => encode (j (a.decode k)).val

/-- Exact equality for two axis choices under faithful natural coordinate observation. -/
def AxisAgreement : Prop := ∀ {r : Nat} (s : Shape r) (k l : Fin r),
    (∀ j : Index s, (j k).val = (j l).val) ↔
    (Nonempty (Index s) → (k = l ∨ (s k = 1 ∧ s l = 1)))
end RevisedBenchmark.BroadcastAxis
