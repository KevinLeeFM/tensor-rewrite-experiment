import GuardSpec
namespace CompressedChain
def BoundedAddressGate := ∀ {n} {s t : Frame n} (c : Chain n s t), (∀ i, total c i=i) →
    ∀ (w : Fin n → Nat) (a : Digits s → Nat) (b : Digits t → Nat),
      (∀ y, validUnit t y → (∀ i, y (slot t i) < w i) → a (expand s (y ∘ slot t)) = b y) →
      ∀ y, validUnit t y → (∀ i, y (slot t i) < w i) →
        ∀ (α : Type) (storage : Nat → α), storage (a (back c y)) = storage (b y)
end CompressedChain
