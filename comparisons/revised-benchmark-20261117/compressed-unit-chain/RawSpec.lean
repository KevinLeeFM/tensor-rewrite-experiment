import ChainSpec
namespace CompressedChain
open TensorRewrite.Pilot
/-- Dense major-to-minor layout: a permutation of the live logical axes, plus
    a physical insertion point for the optional singleton. -/
def address (s : Frame n) (physicalUnit : Fin (n+1)) (order : AxisPermutation n)
    (w : Fin n → Nat) (z : Digits s) : Nat :=
  let live := List.ofFn (fun j => let i := order.outputToInput j; (w i, z (slot s i)))
  ordinal (match s, z with
    | .plain, _ => live
    | .unit u, y => live.insertIdx physicalUnit.val (1,y u)) 0
def RawGate := ∀ {n} {s t : Frame n} (c : Chain n s t), (∀ i, total c i = i) →
  ∀ (su tu : Fin (n+1)) (order : AxisPermutation n) w y, validUnit t y →
    ∀ (α : Type) (storage : Nat → α),
      storage (address s su order w (back c y)) = storage (address t tu order w y)
end CompressedChain
