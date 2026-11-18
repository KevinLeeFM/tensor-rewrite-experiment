import Std
set_option autoImplicit false
namespace RevisedBenchmark.Roundtrip
abbrev Size := BitVec 32
def padToStatic {A : Type} (cap : Nat) (x : List A) (padding : Fin (cap-x.length) → A) :
    List A × Size := (x ++ List.ofFn padding, BitVec.ofNat 32 x.length)
def visibleSize (clamped : Bool) (bound : Size) (size : Size) : Int :=
  if clamped then max 0 (min size.toInt bound.toInt) else size.toInt
def sliceToDynamic {A : Type} (storage : List A) (size : Int) := storage.take size.toNat

/-- Equality of ordered logical values includes the runtime extent (list length). -/
def Case : Prop := ∀ (A : Type) (cap : Nat) (x : List A) (_ : x.length ≤ cap)
    (_ : x.length < 2^31) (clamped : Bool) (_ : clamped = true → cap < 2^31)
    (pad : Fin (cap-x.length) → A),
  let out := padToStatic cap x pad
  sliceToDynamic out.1 (visibleSize clamped (BitVec.ofNat 32 cap) out.2) = x
end RevisedBenchmark.Roundtrip
