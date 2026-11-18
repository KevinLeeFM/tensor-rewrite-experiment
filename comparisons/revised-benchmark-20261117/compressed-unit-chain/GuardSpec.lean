import ChainSpec
namespace CompressedChain
/-- The endpoint target hook guarantees equal physical cell addresses at
corresponding (reshape-paired) rows, independently of any chain. -/
def SameAddress {s t : Frame n} (a : Digits s → Nat) (b : Digits t → Nat) :=
  ∀ y, validUnit t y → a (expand s (y ∘ slot t)) = b y
def GuardGate := ∀ {n} {s t : Frame n} (c : Chain n s t), (∀ i, total c i=i) →
  ∀ a b, SameAddress (s:=s) (t:=t) a b → ∀ y, validUnit t y →
    ∀ (α : Type) (storage : Nat → α), storage (a (back c y)) = storage (b y)
end CompressedChain
